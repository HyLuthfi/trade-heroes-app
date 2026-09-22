import os
import sys
import mimetypes
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler

WEB_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'build', 'web')

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
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

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

    def do_GET(self):
        # Normalize requested path
        clean_path = self.path.split('?')[0].split('#')[0]
        local_fs_path = os.path.normpath(os.path.join(WEB_DIR, clean_path.lstrip('/')))

        # If requested path does not exist on disk and is not a sub-file with extension, fallback to index.html (SPA)
        if not os.path.exists(local_fs_path):
            _, ext = os.path.splitext(clean_path)
            if not ext:
                self.path = '/index.html'

        return super().do_GET()

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
