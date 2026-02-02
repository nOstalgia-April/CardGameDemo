from http.server import HTTPServer, SimpleHTTPRequestHandler
import sys

class CrossOriginHTTPRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Access-Control-Allow-Origin", "*")
        super().end_headers()

if __name__ == '__main__':
    port = 8060
    print(f"Serving on port {port} with Cross-Origin Isolation...")
    httpd = HTTPServer(('0.0.0.0', port), CrossOriginHTTPRequestHandler)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
