#!/usr/bin/env python3
"""풀런봇 진행 줄 수집기.

봇은 브라우저 안에서 돌기 때문에 진행 로그가 브라우저 콘솔에만 남는다. 그 콘솔을
밖에서 읽으려면 WebDriver `/se/log`를 호출해야 하고, 그 호출은 `flutter drive`가
같은 세션에서 쓰는 명령과 겹친다. 그래서 브라우저가 직접 이 수집기로 한 줄씩
POST하게 하고, 여기서 파일에 붙여 쓴다. WebDriver는 전혀 건드리지 않는다.

사용법: full_run_progress_server.py <port> <output-file>
"""
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer


class Handler(BaseHTTPRequestHandler):
    output_path = None

    def do_POST(self):
        length = int(self.headers.get('Content-Length') or 0)
        line = self.rfile.read(length).decode('utf-8', 'replace').strip()
        if line:
            with open(self.output_path, 'a') as f:
                f.write(line + '\n')
                f.flush()
        self.send_response(204)
        # 앱은 web server 포트에서 오므로 요청이 cross-origin이다. 단순 POST라
        # preflight는 없지만, 응답을 막으면 앱 쪽에 오류가 쌓인다.
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()

    def log_message(self, *args):
        pass


def main():
    port = int(sys.argv[1])
    Handler.output_path = sys.argv[2]
    HTTPServer(('127.0.0.1', port), Handler).serve_forever()


if __name__ == '__main__':
    main()
