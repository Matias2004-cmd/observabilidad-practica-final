"""Receptor de Webhook que simula un canal de avisos (Slack/PagerDuty/Teams).

POST /alert -> recibe el JSON de Grafana Alerting y lo imprime en stdout.
GET  /      -> muestra en el navegador las últimas alertas recibidas (evidencia).
"""
import json
from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer

RECEIVED = []


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length).decode("utf-8", errors="replace")
        try:
            payload = json.loads(body)
        except json.JSONDecodeError:
            payload = {"raw": body}
        received_at = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        RECEIVED.insert(0, {"received_at": received_at, "payload": payload})
        del RECEIVED[50:]

        print("=" * 70)
        print(f"[{received_at}] AVISO RECIBIDO - estado: {payload.get('status', '?').upper()}")
        for alert in payload.get("alerts", []):
            labels = alert.get("labels", {})
            print(f"  - {labels.get('alertname')} | severidad={labels.get('severity')} "
                  f"| instancia={labels.get('instance')} | {alert.get('status')}")
            print(f"    {alert.get('annotations', {}).get('summary', '')}")
        print("=" * 70)

        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"ok")

    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.end_headers()
        self.wfile.write(json.dumps(
            {"total": len(RECEIVED), "alertas": RECEIVED}, indent=2, ensure_ascii=False
        ).encode("utf-8"))

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    print("Webhook receiver escuchando en :5001 (POST /alert)")
    HTTPServer(("0.0.0.0", 5001), Handler).serve_forever()
