"""Serve a Flutter web build and proxy its existing API on the same origin.

python scripts/preview.py --port 8080
No credentials are stored. Binds to localhost only.
"""
import argparse
import functools
import http.server
import pathlib
import urllib.error
import urllib.request


class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if self.path.startswith('/api/'):
            self.proxy()
        else:
            super().do_GET()

    def do_POST(self):
        if self.path.startswith('/api/'):
            self.proxy()
        else:
            self.send_error(405)

    def proxy(self):
        length = int(self.headers.get('Content-Length', '0'))
        if length > 8 * 1024 * 1024:
            self.send_error(413)
            return
        data = self.rfile.read(length) if length else None
        request = urllib.request.Request(
            'https://jeju-tour-six.vercel.app' + self.path,
            data=data, method=self.command,
            headers={'Content-Type': self.headers.get('Content-Type', 'application/json'), 'Accept': 'application/json'},
        )
        try:
            response = urllib.request.urlopen(request, timeout=70)
        except urllib.error.HTTPError as error:
            response = error
        except (OSError, urllib.error.URLError):
            self.send_error(502, 'Upstream API unavailable')
            return
        with response:
            content = response.read()
            self.send_response(response.status)
            self.send_header('Content-Type', response.headers.get('Content-Type', 'application/json'))
            self.send_header('Content-Length', str(len(content)))
            self.send_header('Cache-Control', 'no-store')
            self.end_headers()
            self.wfile.write(content)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=8080)
    args = parser.parse_args()
    root = pathlib.Path(__file__).resolve().parents[1] / 'build' / 'web'
    if not (root / 'index.html').exists():
        parser.error('Run flutter build web first.')
    server = http.server.ThreadingHTTPServer(('127.0.0.1', args.port), functools.partial(Handler, directory=str(root)))
    print(f'OREUM IT preview: http://127.0.0.1:{args.port}', flush=True)
    server.serve_forever()
