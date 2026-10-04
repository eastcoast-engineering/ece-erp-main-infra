#!/usr/bin/python3
"""Minimal form-login service used by Caddy's forward_auth directive."""

from __future__ import annotations

import base64
import hashlib
import hmac
import html
import json
import os
import secrets
import time
from http import cookies
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs

AUTH_FILE = Path(os.environ["MAILPIT_AUTH_FILE"])
SECRET_FILE = Path(os.environ["MAILPIT_SESSION_SECRET_FILE"])
BIND_HOST, BIND_PORT_TEXT = os.environ.get(
    "MAILPIT_AUTH_BIND", "127.0.0.1:4180"
).rsplit(":", 1)
BIND_PORT = int(BIND_PORT_TEXT)
COOKIE_NAME = "workwife_mailpit_session"
SESSION_SECONDS = 8 * 60 * 60
MAX_FORM_BYTES = 16 * 1024


def _b64encode(value: bytes) -> str:
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode("ascii")


def _b64decode(value: str) -> bytes:
    return base64.urlsafe_b64decode(value + "=" * (-len(value) % 4))


def _accounts() -> dict[str, str]:
    accounts: dict[str, str] = {}
    for line in AUTH_FILE.read_text(encoding="utf-8").splitlines():
        username, separator, password = line.partition(":")
        if separator and username:
            accounts[username] = password
    return accounts


def _session_secret() -> bytes:
    return SECRET_FILE.read_text(encoding="utf-8").strip().encode("ascii")


def _create_session(username: str) -> str:
    payload = _b64encode(
        json.dumps(
            {"username": username, "expires": int(time.time()) + SESSION_SECONDS},
            separators=(",", ":"),
        ).encode("utf-8")
    )
    signature = hmac.new(_session_secret(), payload.encode("ascii"), hashlib.sha256)
    return f"{payload}.{_b64encode(signature.digest())}"


def _session_username(cookie_header: str) -> str | None:
    jar = cookies.SimpleCookie()
    try:
        jar.load(cookie_header)
        token = jar[COOKIE_NAME].value
        payload, supplied_signature = token.rsplit(".", 1)
        expected_signature = hmac.new(
            _session_secret(), payload.encode("ascii"), hashlib.sha256
        ).digest()
        if not secrets.compare_digest(expected_signature, _b64decode(supplied_signature)):
            return None
        claims = json.loads(_b64decode(payload))
        username = claims.get("username")
        if not isinstance(username, str) or claims.get("expires", 0) < time.time():
            return None
        if username not in _accounts():
            return None
        return username
    except (KeyError, ValueError, TypeError, json.JSONDecodeError):
        return None


def _login_page(error: str = "") -> bytes:
    error_markup = (
        f'<p class="error" role="alert">{html.escape(error)}</p>' if error else ""
    )
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Workwife Test Mail</title>
  <style>
    :root {{ color-scheme: light dark; font-family: system-ui, sans-serif; }}
    body {{ margin: 0; min-height: 100vh; display: grid; place-items: center; background: #111827; color: #f9fafb; }}
    main {{ width: min(90vw, 380px); background: #1f2937; padding: 2rem; border-radius: 14px; box-shadow: 0 20px 50px #0008; }}
    h1 {{ margin: 0 0 .4rem; font-size: 1.5rem; }}
    p {{ color: #cbd5e1; }}
    label {{ display: block; margin-top: 1rem; font-weight: 600; }}
    input {{ box-sizing: border-box; width: 100%; margin-top: .4rem; padding: .75rem; border: 1px solid #64748b; border-radius: 8px; background: #0f172a; color: #fff; }}
    button {{ width: 100%; margin-top: 1.25rem; padding: .8rem; border: 0; border-radius: 8px; background: #38bdf8; color: #082f49; font-weight: 700; cursor: pointer; }}
    .error {{ color: #fca5a5; }}
  </style>
</head>
<body>
  <main>
    <h1>Workwife Test Mail</h1>
    <p>Sign in with your engineer mailbox account.</p>
    {error_markup}
    <form method="post" action="/login">
      <label>Email<input name="username" type="email" autocomplete="username" required autofocus></label>
      <label>Password<input name="password" type="password" autocomplete="current-password" required></label>
      <button type="submit">Sign in</button>
    </form>
  </main>
</body>
</html>""".encode("utf-8")


class AuthHandler(BaseHTTPRequestHandler):
    server_version = "WorkwifeMailAuth/1.0"

    def _send_html(self, body: bytes, status: int = 200) -> None:
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("X-Frame-Options", "DENY")
        self.end_headers()
        self.wfile.write(body)

    def _redirect(self, location: str, cookie: str | None = None) -> None:
        self.send_response(303)
        self.send_header("Location", location)
        self.send_header("Cache-Control", "no-store")
        if cookie:
            self.send_header("Set-Cookie", cookie)
        self.end_headers()

    def do_GET(self) -> None:  # noqa: N802
        if self.path == "/login":
            if _session_username(self.headers.get("Cookie", "")):
                self._redirect("/")
            else:
                self._send_html(_login_page())
            return
        if self.path == "/logout":
            self._redirect(
                "/login",
                f"{COOKIE_NAME}=; Path=/; Max-Age=0; Secure; HttpOnly; SameSite=Lax",
            )
            return
        # Caddy's forward_auth preserves the original requested URI when it
        # probes this service. Treat every other GET as an authorization check.
        if _session_username(self.headers.get("Cookie", "")):
            self.send_response(200)
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
        else:
            self._redirect("/login")

    def do_POST(self) -> None:  # noqa: N802
        if self.path != "/login":
            self.send_error(404)
            return
        try:
            content_length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            self.send_error(400)
            return
        if content_length <= 0 or content_length > MAX_FORM_BYTES:
            self.send_error(400)
            return
        form = parse_qs(self.rfile.read(content_length).decode("utf-8"))
        username = form.get("username", [""])[0].strip()
        password = form.get("password", [""])[0]
        stored_password = _accounts().get(username)
        if stored_password is not None and secrets.compare_digest(
            stored_password, password
        ):
            session = _create_session(username)
            self._redirect(
                "/",
                f"{COOKIE_NAME}={session}; Path=/; Max-Age={SESSION_SECONDS}; Secure; HttpOnly; SameSite=Lax",
            )
            return
        time.sleep(1)
        self._send_html(_login_page("Invalid email or password."), 401)

    def log_message(self, format: str, *args: object) -> None:
        print(f"{self.client_address[0]} - {format % args}", flush=True)


if __name__ == "__main__":
    ThreadingHTTPServer((BIND_HOST, BIND_PORT), AuthHandler).serve_forever()
