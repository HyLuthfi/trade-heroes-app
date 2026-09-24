import os
import re
import json
import struct
import base64
import sqlite3
import asyncio
import urllib.request
import urllib.error
import concurrent.futures

_gemini_keys_cache = []
_gemini_key_index = 0

def get_gemini_keys():
    """Retrieve Gemini API keys from 9Router local database or environment variables."""
    global _gemini_keys_cache
    if _gemini_keys_cache:
        return _gemini_keys_cache

    keys = []
    # 1. Check environment variables
    for env_name in ['GEMINI_API_KEY', 'GOOGLE_API_KEY', 'GEMINI_TTS_KEY']:
        k = os.environ.get(env_name)
        if k and k.strip() and k.strip() not in keys:
            keys.append(k.strip())

    # 2. Check 9Router SQLite Database (auto round-robin pool)
    db_path = os.path.expanduser('~/AppData/Roaming/9router/db/data.sqlite')
    if os.path.exists(db_path):
        try:
            conn = sqlite3.connect(db_path)
            c = conn.cursor()
            c.execute("SELECT data FROM providerConnections WHERE provider='gemini';")
            for r in c.fetchall():
                try:
                    d = json.loads(r[0])
                    api_key = d.get('apiKey')
                    if api_key and api_key.strip() and api_key.strip() not in keys:
                        keys.append(api_key.strip())
                except Exception:
                    pass
            conn.close()
        except Exception as e:
            print(f"Notice: Failed reading 9Router DB for Gemini keys: {e}")

    _gemini_keys_cache = keys
    return keys

def clean_text_for_speech(text: str) -> str:
    """Strip markdown formatting, emojis, and symbols so TTS speaks smooth spoken Indonesian."""
    if not text:
        return ""
    # Remove thought blocks
    t = re.sub(r'<think[\s>].*?</think>', '', text, flags=re.DOTALL)
    # Remove code blocks
    t = re.sub(r'```.*?```', '', t, flags=re.DOTALL)
    # Remove inline code
    t = re.sub(r'`(.*?)`', r'\1', t)
    # Remove bold / italic markdown
    t = re.sub(r'\*\*(.*?)\*\*', r'\1', t)
    t = re.sub(r'\*(.*?)\*', r'\1', t)
    # Remove markdown headers
    t = re.sub(r'#+\s*', '', t)
    # Remove bullet markers
    t = re.sub(r'[•\-\*]\s+', '', t)
    # Replace arrows
    t = t.replace('->', ' ke ')
    # Remove brackets
    t = re.sub(r'[\[\]\(\)\{\}]', ' ', t)
    # Normalize spaces
    t = re.sub(r'\s+', ' ', t).strip()
    return t

def wrap_pcm_wav(pcm_bytes: bytes, sample_rate: int = 24000, channels: int = 1, sample_width: int = 2) -> bytes:
    """Wrap raw 24kHz signed-little-endian 16-bit mono PCM into a standard 44-byte RIFF WAV header."""
    block_align = channels * sample_width
    fmt_chunk = struct.pack(
        '<4sIHHIIHH',
        b'fmt ', 16, 1, channels, sample_rate,
        sample_rate * block_align, block_align, sample_width * 8
    )
    data_chunk = struct.pack('<4sI', b'data', len(pcm_bytes))
    riff_header = struct.pack(
        '<4sI4s',
        b'RIFF', 4 + len(fmt_chunk) + len(data_chunk) + len(pcm_bytes), b'WAVE'
    )
    return riff_header + fmt_chunk + data_chunk + pcm_bytes

def synthesize_edge_tts(clean_text: str, voice: str = "id-ID-GadisNeural") -> str:
    """Fallback generator using Microsoft Edge TTS (id-ID-GadisNeural) for ultra-fast, zero-rate-limit audio."""
    try:
        import edge_tts

        async def _run():
            communicate = edge_tts.Communicate(clean_text, voice)
            audio_bytes = b''
            async for chunk in communicate.stream():
                if chunk['type'] == 'audio':
                    audio_bytes += chunk['data']
            return audio_bytes

        try:
            loop = asyncio.get_event_loop()
            if loop.is_running():
                with concurrent.futures.ThreadPoolExecutor() as executor:
                    data = executor.submit(asyncio.run, _run()).result(timeout=8)
            else:
                data = loop.run_until_complete(_run())
        except RuntimeError:
            data = asyncio.run(_run())

        if data:
            return f"data:audio/mp3;base64,{base64.b64encode(data).decode('utf-8')}"
    except Exception as e:
        print(f"Edge TTS fallback error: {e}")
    return ""

def synthesize_gemini_tts(text: str, voice: str = "Puck", model: str = "gemini-2.5-flash-preview-tts") -> str:
    """
    Generate spoken voice audio via Google Gemini Generative Audio API,
    with automatic ultra-fast fallback to Microsoft Edge TTS (id-ID-GadisNeural)
    if Gemini encounters rate limits or latency.
    """
    global _gemini_key_index
    clean_text = clean_text_for_speech(text)
    if not clean_text:
        return ""

    keys = get_gemini_keys()
    num_keys = len(keys)

    if num_keys > 0:
        prompt_text = f"Please read the following text aloud naturally and expressively in Indonesian without adding or replying anything:\n\n{clean_text}"
        payload = {
            "contents": [{"parts": [{"text": prompt_text}]}],
            "generationConfig": {
                "responseModalities": ["AUDIO"],
                "speechConfig": {
                    "voiceConfig": {
                        "prebuiltVoiceConfig": {
                            "voiceName": voice
                        }
                    }
                }
            }
        }
        json_bytes = json.dumps(payload).encode('utf-8')

        # Try 1 key with short timeout (2.8s) so response never hangs
        max_retries = min(1, num_keys)
        for attempt in range(max_retries):
            idx = (_gemini_key_index + attempt) % num_keys
            key = keys[idx]
            url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"

            try:
                req = urllib.request.Request(
                    url,
                    data=json_bytes,
                    headers={"Content-Type": "application/json"}
                )
                with urllib.request.urlopen(req, timeout=2.8) as resp:
                    if resp.status == 200:
                        data = json.loads(resp.read().decode('utf-8'))
                        candidates = data.get("candidates", [])
                        if candidates:
                            parts = candidates[0].get("content", {}).get("parts", [])
                            audio_part = next((p for p in parts if "inlineData" in p or "inline_data" in p), None)
                            if audio_part:
                                b64 = (audio_part.get("inlineData") or audio_part.get("inline_data") or {}).get("data", "")
                                if b64:
                                    pcm = base64.b64decode(b64)
                                    wav = wrap_pcm_wav(pcm)
                                    _gemini_key_index = (idx + 1) % num_keys
                                    return f"data:audio/wav;base64,{base64.b64encode(wav).decode('utf-8')}"
            except Exception as ex:
                print(f"Gemini TTS notice: {ex}, switching directly to fast Edge TTS...")
                break

    # Fallback to high-speed Edge TTS
    return synthesize_edge_tts(clean_text)
