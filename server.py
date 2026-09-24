import os
import sys
import mimetypes
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler

# Import in-repo quantitative trading knowledge engine
try:
    from engine.quant_hub import analyze_stock_quant
except Exception as _e:
    analyze_stock_quant = None
    print(f"Notice: engine.quant_hub import status: {_e}")

WEB_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'build', 'web')

def get_router_key():
    k = os.environ.get('ROUTER_API_KEY') or os.environ.get('HERMES_CUSTOM_LOCALHOST_20128_API_KEY')
    if k:
        return k
    env_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), '.env.local')
    if os.path.exists(env_file):
        try:
            with open(env_file, 'r', encoding='utf-8') as f:
                for line in f:
                    if line.startswith('ROUTER_API_KEY='):
                        return line.strip().split('=', 1)[1]
        except Exception:
            pass
    return ''

# Ensure standard MIME types are properly registered
mimetypes.add_type('application/javascript', '.js')
mimetypes.add_type('application/javascript', '.mjs')
mimetypes.add_type('application/wasm', '.wasm')
mimetypes.add_type('application/json', '.json')
mimetypes.add_type('video/mp4', '.mp4')
mimetypes.add_type('image/svg+xml', '.svg')
mimetypes.add_type('image/webp', '.webp')
mimetypes.add_type('image/x-icon', '.ico')

class RobustThreadingServer(ThreadingHTTPServer):
    daemon_threads = True
    allow_reuse_address = True

    def handle_error(self, request, client_address):
        exc_type, _, _ = sys.exc_info()
        if exc_type in (ConnectionResetError, BrokenPipeError, ConnectionAbortedError):
            return
        super().handle_error(request, client_address)

class FlutterWebHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def end_headers(self):
        # Security & CORS headers suitable for Flutter Web
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, HEAD')
        self.send_header('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept, Range')
        self.send_header('X-Content-Type-Options', 'nosniff')
        # Prevent browser & PWA caching stale JS during development
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate, max-age=0')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

    def do_HEAD(self):
        if self.path.startswith('/api/yahoo/') or self.path.startswith('/api/news'):
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            return
        super().do_HEAD()

    def do_OPTIONS(self):
        self.send_response(200, "OK")
        self.end_headers()

    def copyfile(self, source, outputfile):
        try:
            super().copyfile(source, outputfile)
        except (ConnectionResetError, BrokenPipeError, ConnectionAbortedError):
            pass

    def handle_one_request(self):
        try:
            super().handle_one_request()
        except (ConnectionResetError, BrokenPipeError, ConnectionAbortedError):
            pass

    def do_POST(self):
        if self.path.startswith('/api/ai/live-stream'):
            self._handle_ai_live_stream()
            return
        if self.path.startswith('/api/ai/chat'):
            self._handle_ai_chat()
            return
        if self.path.startswith('/api/ai/tts'):
            self._handle_ai_tts()
            return
        self.send_response(404)
        self.end_headers()

    def _handle_ai_live_stream(self):
        """Streaming Live Voice endpoint: SSE stream of progressive text deltas and chunked audio synthesized on sentence boundaries"""
        import json
        import re
        import threading
        import queue
        import urllib.request
        from engine.tts_service import synthesize_voice

        try:
            content_len = int(self.headers.get('Content-Length', 0))
            post_body = self.rfile.read(content_len)
            req_data = json.loads(post_body.decode('utf-8'))
        except Exception:
            self.send_response(400)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"error":"invalid json"}')
            return

        prompt = req_data.get('prompt', '')
        ticker = req_data.get('ticker', 'BBCA').upper().replace('.JK', '')
        stock = req_data.get('stock', {})
        name = stock.get('name', ticker)
        sector = stock.get('sector', 'Umum')
        voice_engine = req_data.get('voiceEngine') or 'gemini_charon'

        # 1. Fetch live price
        live_price = stock.get('price', '-')
        live_chg_pct = stock.get('changePct', '-')
        day_low = stock.get('low', '-')
        day_high = stock.get('high', '-')
        day_vol = stock.get('volume', '-')
        trend_5d = ""
        try:
            yf_url = f"https://query1.finance.yahoo.com/v8/finance/chart/{ticker}.JK?interval=1d&range=5d"
            yf_req = urllib.request.Request(yf_url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(yf_req, timeout=3.5) as yf_resp:
                yf_data = json.loads(yf_resp.read().decode('utf-8'))
                meta = yf_data.get('chart', {}).get('result', [{}])[0].get('meta', {})
                quotes = yf_data.get('chart', {}).get('result', [{}])[0].get('indicators', {}).get('quote', [{}])[0]
                if meta.get('regularMarketPrice'):
                    live_price = f"{meta['regularMarketPrice']:,.0f}".replace(',', '.')
                if meta.get('regularMarketDayLow'):
                    day_low = f"{meta['regularMarketDayLow']:,.0f}".replace(',', '.')
                if meta.get('regularMarketDayHigh'):
                    day_high = f"{meta['regularMarketDayHigh']:,.0f}".replace(',', '.')
                closes = [c for c in quotes.get('close', []) if c is not None]
                if len(closes) >= 2:
                    first_p = closes[0]
                    last_p = closes[-1]
                    chg = ((last_p - first_p) / first_p) * 100
                    live_chg_pct = f"{chg:+.2f}%"
                    trend_5d = "Menguat (Bullish)" if chg > 0.5 else ("Melemah (Bearish)" if chg < -0.5 else "Konsolidasi")
        except Exception:
            pass

        # 2. Quant context
        quant_context = ""
        try:
            from engine.quant_hub import analyze_stock_quant
            q_res = analyze_stock_quant(ticker)
            if q_res and 'summary' in q_res:
                quant_context = f"Indikator Kuantitatif: {q_res['summary']}. Support terdekat: Rp {q_res.get('support', day_low)}. Resisten terdekat: Rp {q_res.get('resistance', day_high)}."
        except Exception:
            pass

        # 3. System prompt tailored for rapid spoken live voice delivery
        system_prompt = (
            f"Kamu adalah SAI Tech AI Chatbot, analis pasar modal Indonesia (BEI) di Trade Heroes.\n"
            f"Saham: {ticker} ({name}) • Sektor: {sector}\n"
            f"Data BEI: Harga Rp {live_price} ({live_chg_pct}), Low {day_low} - High {day_high}, Tren: {trend_5d if trend_5d else 'Stabil'}.\n"
            f"{quant_context}\n\n"
            f"ATURAN FORMAT JAWABAN LIVE VOICE (SANGAT PENTING):\n"
            f"- Jawabanmu akan langsung disintesis menjadi suara percakapan lisan.\n"
            f"- Buat HANYA 2 kalimat padat, natural, santai, to-the-point.\n"
            f"- Kalimat 1: Langsung sebutkan tren dan posisi harga terkini (maks 10-12 kata).\n"
            f"- Kalimat 2: Sebutkan level support resisten kunci dan rekomendasi tindakan praktis.\n"
            f"- DILARANG KERAS menggunakan format markdown (**tebal**, #, list bullet, tabel, dsb). Murni teks mengalir."
        )

        key = get_router_key()
        history = req_data.get('history', [])
        messages = [{'role': 'system', 'content': system_prompt}]
        for h in history[-4:]:
            r = 'user' if (h.get('isUser') or h.get('role') == 'user') else 'assistant'
            c = (h.get('content') or h.get('text') or '').strip()
            if c:
                messages.append({'role': r, 'content': c})
        if not messages or messages[-1].get('role') != 'user' or messages[-1].get('content') != prompt:
            messages.append({'role': 'user', 'content': prompt})

        # Send SSE Headers
        self.send_response(200)
        self.send_header('Content-Type', 'text/event-stream; charset=utf-8')
        self.send_header('Cache-Control', 'no-cache, no-transform')
        self.send_header('Connection', 'keep-alive')
        self.send_header('X-Accel-Buffering', 'no')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()

        write_lock = threading.Lock()
        is_client_connected = True

        def send_sse(event_type, payload):
            nonlocal is_client_connected
            if not is_client_connected:
                return
            with write_lock:
                try:
                    msg = f"event: {event_type}\ndata: {json.dumps(payload)}\n\n"
                    self.wfile.write(msg.encode('utf-8'))
                    self.wfile.flush()
                except Exception:
                    is_client_connected = False

        sentence_q = queue.Queue()

        def tts_stream_worker():
            nonlocal is_client_connected
            while is_client_connected:
                item = sentence_q.get()
                if item is None:
                    break
                s_idx, s_text = item
                try:
                    tts_res = synthesize_voice(s_text, voice_engine=voice_engine)
                    audio_uri = tts_res.get('audio', '')
                    if audio_uri and is_client_connected:
                        send_sse('audio', {
                            'index': s_idx,
                            'sentence': s_text,
                            'audio': audio_uri,
                            'provider': tts_res.get('provider', '')
                        })
                except Exception as tts_err:
                    print(f"Streaming TTS error for sentence #{s_idx}: {tts_err}")
                finally:
                    sentence_q.task_done()

        tts_thread = threading.Thread(target=tts_stream_worker, daemon=True)
        tts_thread.start()

        # Connect to 9Router stream
        router_payload = {
            'model': 'ag/gemini-3.8-flash-low',
            'messages': messages,
            'stream': True,
            'max_tokens': 120
        }

        full_reply_text = ""
        buffer = ""
        sentence_count = 0

        try:
            req = urllib.request.Request(
                'http://127.0.0.1:20128/v1/chat/completions',
                data=json.dumps(router_payload).encode('utf-8'),
                headers={'Content-Type': 'application/json', 'Authorization': f'Bearer {key}'}
            )
            with urllib.request.urlopen(req, timeout=15) as resp:
                for raw_line in resp:
                    if not is_client_connected:
                        break
                    line = raw_line.decode('utf-8').strip()
                    if not line.startswith('data: '):
                        continue
                    data_str = line[6:].strip()
                    if data_str == '[DONE]':
                        break
                    try:
                        chunk = json.loads(data_str)
                        content = chunk.get('choices', [{}])[0].get('delta', {}).get('content', '')
                        if content:
                            full_reply_text += content
                            send_sse('text', {'delta': content, 'accumulated': full_reply_text})
                            buffer += content
                            m = re.search(r'([.!?\n])', buffer)
                            if m:
                                cut_pos = m.end()
                                sent = buffer[:cut_pos].strip()
                                buffer = buffer[cut_pos:].strip()
                                if len(sent) > 5:
                                    sentence_count += 1
                                    sentence_q.put((sentence_count, sent))
                    except Exception:
                        pass
        except Exception as e:
            send_sse('error', {'error': str(e)})

        # Flush any remaining text in buffer
        if buffer.strip() and is_client_connected:
            sentence_count += 1
            sentence_q.put((sentence_count, buffer.strip()))

        sentence_q.put(None)
        tts_thread.join(timeout=30)

        if is_client_connected:
            send_sse('done', {'fullText': full_reply_text, 'sentences': sentence_count})

    def _handle_ai_tts(self):
        """Synthesize text to speech using Google Gemini or Microsoft Edge TTS"""
        import json
        try:
            content_len = int(self.headers.get('Content-Length', 0))
            post_body = self.rfile.read(content_len)
            req_data = json.loads(post_body.decode('utf-8'))
        except Exception:
            self.send_response(400)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"error":"invalid json"}')
            return

        text = req_data.get('text', '')
        voice = req_data.get('voice', 'auto')
        try:
            from engine.tts_service import synthesize_voice
            res = synthesize_voice(text, voice_engine=voice)
            self.send_response(200)
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.end_headers()
            self.wfile.write(json.dumps({'audio': res.get('audio', ''), 'provider': res.get('provider', '')}).encode('utf-8'))
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode('utf-8'))

    def do_GET(self):
        # --- Real-Time Financial News API ---
        if self.path.startswith('/api/news'):
            self._handle_news()
            return

        # --- Yahoo Finance API Proxy (avoids CORS for Flutter Web) ---
        if self.path.startswith('/api/yahoo/'):
            self._proxy_yahoo()
            return

        # Normalize requested path
        clean_path = self.path.split('?')[0].split('#')[0]
        local_fs_path = os.path.normpath(os.path.join(WEB_DIR, clean_path.lstrip('/')))

        # Handle Flutter Web asset path aliasing (/assets/audio/... -> /assets/assets/audio/...)
        if not os.path.exists(local_fs_path):
            if clean_path.startswith('/assets/'):
                nested_path = os.path.normpath(os.path.join(WEB_DIR, 'assets', clean_path.lstrip('/')))
                if os.path.exists(nested_path):
                    self.path = '/assets' + clean_path
                    return super().do_GET()

            _, ext = os.path.splitext(clean_path)
            if not ext:
                self.path = '/index.html'

        return super().do_GET()

    def _proxy_yahoo(self):
        """Proxy Yahoo Finance API requests to avoid CORS"""
        import urllib.request, urllib.error
        # /api/yahoo/chart/BBCA.JK?interval=5m&range=1d
        rest = self.path[len('/api/yahoo/'):]
        yahoo_url = f'https://query1.finance.yahoo.com/v8/finance/{rest}'
        try:
            req = urllib.request.Request(yahoo_url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=10) as resp:
                body = resp.read()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(body)
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"error":"upstream error"}')
        except Exception:
            self.send_response(502)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"error":"proxy failed"}')

    def _handle_news(self):
        """Fetch real-time Indonesian financial news via Google News RSS for stock ticker"""
        import urllib.parse, json
        query = urllib.parse.urlparse(self.path).query
        params = urllib.parse.parse_qs(query)
        ticker = params.get('ticker', ['BBCA'])[0].upper().replace('.JK', '').strip()

        try:
            from engine.news_service import fetch_stock_news
            articles = fetch_stock_news(ticker)
        except Exception as e:
            articles = []
            print(f"News fetch error for {ticker}: {e}")

        self.send_response(200)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.end_headers()
        self.wfile.write(json.dumps({'ticker': ticker, 'articles': articles}).encode('utf-8'))

    def _handle_ai_chat(self):
        """Proxy AI Chat requests to 9Router with live real-time market data from Yahoo Finance"""
        import urllib.request, urllib.error, json
        try:
            content_len = int(self.headers.get('Content-Length', 0))
            post_body = self.rfile.read(content_len)
            req_data = json.loads(post_body.decode('utf-8'))
        except Exception:
            self.send_response(400)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"error":"invalid json"}')
            return

        prompt = req_data.get('prompt', '')
        ticker = req_data.get('ticker', 'BBCA').upper().replace('.JK', '')
        stock = req_data.get('stock', {})
        name = stock.get('name', ticker)
        sector = stock.get('sector', 'Umum')

        # 1. Fetch freshest live tick data from Yahoo Finance BEI
        live_price = stock.get('price', '-')
        live_chg_pct = stock.get('changePct', '-')
        day_high = '-'
        day_low = '-'
        day_vol = '-'
        trend_5d = ''

        try:
            yf_url = f'https://query1.finance.yahoo.com/v8/finance/chart/{ticker}.JK?interval=1d&range=5d'
            yf_req = urllib.request.Request(yf_url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(yf_req, timeout=3) as yf_resp:
                yf_data = json.loads(yf_resp.read().decode('utf-8'))
                res0 = yf_data.get('chart', {}).get('result', [{}])[0]
                meta = res0.get('meta', {})
                quotes = res0.get('indicators', {}).get('quote', [{}])[0]
                closes = quotes.get('close', [])

                if meta.get('regularMarketPrice'):
                    live_price = f"{meta['regularMarketPrice']:,.0f}".replace(',', '.')
                prev_c = meta.get('previousClose') or meta.get('chartPreviousClose')
                cur_p = meta.get('regularMarketPrice')
                if cur_p and prev_c:
                    diff = cur_p - prev_c
                    pct = (diff / prev_c) * 100
                    live_chg_pct = f"{'+' if pct >= 0 else ''}{pct:.2f}%"
                if meta.get('regularMarketDayHigh'):
                    day_high = f"{meta['regularMarketDayHigh']:,.0f}".replace(',', '.')
                if meta.get('regularMarketDayLow'):
                    day_low = f"{meta['regularMarketDayLow']:,.0f}".replace(',', '.')
                if meta.get('regularMarketVolume'):
                    day_vol = f"{meta['regularMarketVolume']:,}".replace(',', '.')
                if closes:
                    valid_closes = [int(c) for c in closes if c is not None]
                    if valid_closes:
                        trend_5d = " -> ".join([f"Rp {c}" for c in valid_closes[-5:]])
        except Exception as e:
            print(f"Warning: Live tick fetch failed for {ticker}: {e}")

        # 2. Run in-repo Quant Engine (SNR Channels + SMC Fair Value Gaps + ZeroLag Momentum)
        quant_context = ""
        if analyze_stock_quant:
            try:
                qres = analyze_stock_quant(ticker)
                quant_context = qres.get("prompt_context", "")
            except Exception as q_err:
                print(f"Quant analysis error for {ticker}: {q_err}")

        # 3. Build contextual real-time prompt with full quant insights
        is_live_voice = bool(req_data.get('liveVoice') or req_data.get('voice'))
        voice_style_instruction = ""
        if is_live_voice:
            voice_style_instruction = (
                "\nUser saat ini berinteraksi melalui Mode Percakapan Suara Langsung (Live Voice).\n"
                "- Buat jawabanmu lisan, santai, ringkas (maksimal 2–3 kalimat langsung ke inti analisa).\n"
                "- JANGAN gunakan format markdown seperti bintang **, pagar #, bullet point •, atau simbol tabel.\n"
                "- Gunakan kata-kata yang mengalir alami saat diucapkan seperti analis profesional yang sedang berbicara langsung."
            )

        system_prompt = (
            f"Kamu adalah SAI Tech AI Chatbot, asisten cerdas analis pasar modal Indonesia (BEI) di platform edukasi Trade Heroes.\n"
            f"Karakter: Analis kuantitatif & edukator saham profesional, ramah, to-the-point, dan zero basa-basi.\n"
            f"Saham yang sedang aktif: {ticker} ({name}) • Sektor: {sector}\n\n"
            f"DATA REAL-TIME BURSA EFEK INDONESIA (BEI) HARI INI:\n"
            f"- Harga Terkini: Rp {live_price} ({live_chg_pct})\n"
            f"- Rentang Hari Ini: Low Rp {day_low} — High Rp {day_high}\n"
            f"- Volume Perdagangan: {day_vol} lembar saham\n"
            f"- Tren Penutupan 5 Hari Terakhir: {trend_5d if trend_5d else 'Stabil'}\n"
            f"- PER: {stock.get('per', '15.0')}x | PBV: {stock.get('pbv', '2.0')}x | Market Cap: {stock.get('mcap', '-')}\n\n"
            f"{quant_context}\n\n"
            f"Petunjuk Format Output & Edukasi:\n"
            f"- Berikan edukasi yang taktis (Level Support & Resistance aktual, Imbalance harga, dan Strategi Trading/Investasi yang jelas).\n"
            f"- Jangan gunakan kalimat klise pembuka seperti 'Tentu, saya bisa bantu'. Langsung sajikan analisa tajam, edukatif, dan bernilai tinggi."
            f"{voice_style_instruction}"
        )

        key = get_router_key()

        # 4. Multi-turn Conversation Memory
        history = req_data.get('history', [])
        messages = [{'role': 'system', 'content': system_prompt}]

        for h in history[-8:]:
            r = 'user' if (h.get('isUser') or h.get('role') == 'user') else 'assistant'
            c = (h.get('content') or h.get('text') or '').strip()
            if c:
                messages.append({'role': r, 'content': c})

        # Ensure current prompt is at the end
        if not messages or messages[-1].get('role') != 'user' or messages[-1].get('content') != prompt:
            messages.append({'role': 'user', 'content': prompt})

        router_payload = {
            'model': 'ag/gemini-3.8-flash-low',
            'messages': messages,
            'stream': False,
            'max_tokens': 140 if is_live_voice else 450
        }

        try:
            req = urllib.request.Request(
                'http://127.0.0.1:20128/v1/chat/completions',
                data=json.dumps(router_payload).encode('utf-8'),
                headers={
                    'Content-Type': 'application/json',
                    'Authorization': f'Bearer {key}'
                }
            )
            with urllib.request.urlopen(req, timeout=12) as resp:
                resp_body = resp.read().decode('utf-8').strip()
                ai_text = ""
                if resp_body.startswith("data: ") or "\ndata: " in resp_body:
                    for line in resp_body.splitlines():
                        line = line.strip()
                        if line.startswith("data: "):
                            line_data = line[6:].strip()
                            if line_data == "[DONE]":
                                break
                            try:
                                chunk = json.loads(line_data)
                                delta = chunk.get("choices", [{}])[0].get("delta", {})
                                content_piece = delta.get("content", "")
                                if content_piece:
                                    ai_text += content_piece
                            except Exception:
                                pass
                else:
                    data = json.loads(resp_body)
                    ai_text = data.get('choices', [{}])[0].get('message', {}).get('content', '')

            audio_uri = ""
            tts_provider = ""
            if is_live_voice:
                try:
                    from engine.tts_service import synthesize_voice
                    v_engine = req_data.get('voiceEngine') or req_data.get('voiceName') or 'auto'
                    tts_res = synthesize_voice(ai_text, voice_engine=v_engine)
                    audio_uri = tts_res.get('audio', '')
                    tts_provider = tts_res.get('provider', '')
                except Exception as tts_err:
                    print(f"Warning: Live voice synthesis failed: {tts_err}")

            self.send_response(200)
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.end_headers()
            self.wfile.write(json.dumps({'reply': ai_text, 'audio': audio_uri, 'provider': tts_provider}).encode('utf-8'))
        except Exception as e:
            self.send_response(200)
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e), 'fallback': True}).encode('utf-8'))

def run(port=20170):
    if not os.path.isdir(WEB_DIR):
        print(f"Error: Web directory does not exist: {WEB_DIR}")
        sys.exit(1)

    server_address = ('0.0.0.0', port)
    httpd = RobustThreadingServer(server_address, FlutterWebHandler)
    print(f"Trade Heroes Web Server active on port {port} (0.0.0.0:{port})")
    print(f"Serving web root: {WEB_DIR}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else int(os.environ.get('PORT', 20170))
    run(port)
