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

    # Prioritize healthy keys (rotate initial index to confirmed responsive keys)
    _gemini_keys_cache = keys
    return keys

def clean_text_for_speech(text: str) -> str:
    """Strip markdown formatting, emojis, and symbols so TTS speaks smooth spoken Indonesian."""
    if not text:
        return ""
    t = re.sub(r'<think[\s>].*?</think>', '', text, flags=re.DOTALL)
    t = re.sub(r'```.*?```', '', t, flags=re.DOTALL)
    t = re.sub(r'`(.*?)`', r'\1', t)
    t = re.sub(r'\*\*(.*?)\*\*', r'\1', t)
    t = re.sub(r'\*(.*?)\*', r'\1', t)
    t = re.sub(r'#+\s*', '', t)
    t = re.sub(r'[•\-\*]\s+', '', t)
    t = t.replace('->', ' ke ')
    t = re.sub(r'[\[\]\(\)\{\}]', ' ', t)
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

def synthesize_edge_tts(clean_text: str, voice: str = "id-ID-ArdiNeural") -> str:
    """
    Generate audio using Microsoft Edge TTS.
    Voices:
    - id-ID-ArdiNeural (Cowok / Pria)
    - id-ID-GadisNeural (Cewek / Wanita)
    """
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
        print(f"Edge TTS ({voice}) error: {e}")
    return ""

def synthesize_voice(text: str, voice_engine: str = "auto") -> dict:
    """
    Main TTS router with explicit model detection.
    voice_engine options:
    - 'gemini_puck': Google Gemini (Puck - Cowok Enerjik)
    - 'gemini_charon': Google Gemini (Charon - Cowok Bariton)
    - 'microsoft_ardi': Microsoft Edge (Ardi - Cowok Berwibawa)
    - 'microsoft_gadis': Microsoft Edge (Gadis - Cewek Edukatif)
    - 'auto': Coba Gemini Cowok (Puck) dulu, jika limit/timeout -> otomatis Microsoft Cowok (Ardi).
    """
    global _gemini_key_index
    clean_text = clean_text_for_speech(text)
    if not clean_text:
        return {"audio": "", "provider": "None"}

    # 1. Direct Microsoft Edge selection
    if voice_engine == "microsoft_ardi" or voice_engine == "ardi":
        audio = synthesize_edge_tts(clean_text, voice="id-ID-ArdiNeural")
        return {"audio": audio, "provider": "Microsoft Edge (Ardi - Cowok)"}

    if voice_engine == "microsoft_gadis" or voice_engine == "gadis":
        audio = synthesize_edge_tts(clean_text, voice="id-ID-GadisNeural")
        return {"audio": audio, "provider": "Microsoft Edge (Gadis - Cewek)"}

    # 2. Gemini selection or Auto (Default: Charon)
    gemini_voice = "Charon"
    if voice_engine == "gemini_puck" or voice_engine == "puck":
        gemini_voice = "Puck"
    model = "gemini-3.8-flash-lite-tts"

    keys = get_gemini_keys()
    num_keys = len(keys)

    # If Gemini requested or Auto mode, attempt Gemini TTS with healthy keys
    if num_keys > 0:
        payload = {
            "contents": [{"parts": [{"text": clean_text}]}],
            "generationConfig": {
                "responseModalities": ["AUDIO"],
                "speechConfig": {
                    "voiceConfig": {
                        "prebuiltVoiceConfig": {
                            "voiceName": gemini_voice
                        }
                    }
                }
            }
        }
        json_bytes = json.dumps(payload).encode('utf-8')

        # If auto, try 1 key with 6s timeout; if explicit gemini requested, give up to 14s timeout
        is_explicit_gemini = voice_engine in ["gemini_puck", "gemini_charon", "puck", "charon"]
        timeout_sec = 14.0 if is_explicit_gemini else 6.0
        max_attempts_count = 2 if is_explicit_gemini else 1

        preferred_indices = [2, 4, 5, 6, 10, 15, 16, 17, 19, 20]
        attempts = [preferred_indices[(_gemini_key_index + i) % len(preferred_indices)] for i in range(min(max_attempts_count, len(preferred_indices)))]

        for idx in attempts:
            if idx >= num_keys:
                continue
            key = keys[idx]
            url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"

            try:
                req = urllib.request.Request(
                    url,
                    data=json_bytes,
                    headers={"Content-Type": "application/json"}
                )
                with urllib.request.urlopen(req, timeout=timeout_sec) as resp:
                    if resp.status == 200:
                        data = json.loads(resp.read().decode('utf-8'))
                        candidates = data.get("candidates", [])
                        if candidates:
                            parts = candidates[0].get("content", {}).get("parts", [])
                            audio_part = next((p for p in parts if "inlineData" in p or "inline_data" in p), None)
                            if audio_part:
                                b64 = (audio_part.get("inlineData") or audio_part.get("inline_data") or {}).get("data", "")
                                if b64:
                                    raw_audio = base64.b64decode(b64)
                                    # If already standard RIFF WAV (Gemini 3.8/2.5 default), use directly
                                    if raw_audio.startswith(b'RIFF'):
                                        wav = raw_audio
                                    else:
                                        wav = wrap_pcm_wav(raw_audio)
                                    _gemini_key_index = (idx + 1) % len(preferred_indices)
                                    return {
                                        "audio": f"data:audio/wav;base64,{base64.b64encode(wav).decode('utf-8')}",
                                        "provider": f"Google Gemini ({gemini_voice} - Cowok)"
                                    }
            except Exception as ex:
                print(f"Gemini Key #{idx} notice: {ex}, trying next...")
                continue

    # Fallback or Forced Microsoft
    print("Switching to Microsoft Edge (Ardi - Cowok)...")
    audio = synthesize_edge_tts(clean_text, voice="id-ID-ArdiNeural")
    return {"audio": audio, "provider": "Microsoft Edge (Ardi - Cowok)"}

def synthesize_gemini_tts(text: str, voice: str = "auto") -> str:
    """Backward compatibility helper returning data URI string."""
    res = synthesize_voice(text, voice_engine=voice)
    return res.get("audio", "")
