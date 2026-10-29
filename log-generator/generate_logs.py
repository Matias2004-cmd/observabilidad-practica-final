"""Simula los logs JSON de una aplicación de microservicios desplegada en la nube.

Escribe una línea JSON por evento en /var/log/cloud-app/app.log, con una
distribución de severidades realista y picos de errores periódicos.
"""
import json
import os
import random
import time
from datetime import datetime, timezone

LOG_FILE = "/var/log/cloud-app/app.log"
MAX_BYTES = 20 * 1024 * 1024  # rota (trunca) al llegar a 20 MB

SERVICES = {
    "api-gateway": ["GET /api/v1/products", "GET /api/v1/cart", "POST /api/v1/login"],
    "payments": ["POST /api/v1/charge", "POST /api/v1/refund"],
    "inventory": ["GET /api/v1/stock", "PUT /api/v1/stock"],
    "auth": ["POST /oauth/token", "GET /oauth/userinfo"],
}
REGIONS = ["us-east-1", "sa-east-1"]

MESSAGES = {
    "DEBUG": ["Cache lookup key={key}", "Payload validado en {ms} ms"],
    "INFO": ["Solicitud procesada correctamente", "Usuario autenticado", "Stock actualizado"],
    "WARN": ["Latencia elevada en dependencia downstream", "Reintento 1/3 hacia base de datos",
             "Pool de conexiones al 85%"],
    "ERROR": ["Upstream timeout hacia payment-provider", "Conexión rechazada por la base de datos",
              "Fallo al deserializar respuesta"],
    "CRITICAL": ["Circuit breaker ABIERTO hacia payment-provider", "Disco de la instancia al 98%"],
}


def pick_level(spike):
    # Cada cierto tiempo hay un "incidente" y suben los errores
    weights = [5, 70, 15, 9, 1] if not spike else [2, 40, 20, 30, 8]
    return random.choices(["DEBUG", "INFO", "WARN", "ERROR", "CRITICAL"], weights)[0]


def build_event(spike):
    level = pick_level(spike)
    service = random.choice(list(SERVICES))
    method, path = random.choice(SERVICES[service]).split(" ")
    if level in ("ERROR", "CRITICAL"):
        status = random.choice([500, 502, 503, 504])
        latency = random.randint(800, 5000)
    elif level == "WARN":
        status = random.choice([200, 429])
        latency = random.randint(400, 1500)
    else:
        status = 200
        latency = random.randint(5, 300)
    message = random.choice(MESSAGES[level]).format(key=random.randint(1, 9999), ms=latency)
    return {
        "timestamp": datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z"),
        "level": level,
        "service": service,
        "cloud": {"provider": "aws", "region": random.choice(REGIONS)},
        "http": {"method": method, "path": path, "status": status},
        "latency_ms": latency,
        "trace_id": os.urandom(16).hex(),
        "message": message,
    }


def healthcheck_event():
    return {
        "timestamp": datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z"),
        "level": "DEBUG",
        "service": "api-gateway",
        "cloud": {"provider": "aws", "region": "us-east-1"},
        "message": "healthcheck OK /health",
    }


def main():
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    print(f"Escribiendo logs simulados en {LOG_FILE}")
    while True:
        # Incidente simulado: 1 minuto de cada 5
        spike = (int(time.time()) // 60) % 5 == 0
        if os.path.exists(LOG_FILE) and os.path.getsize(LOG_FILE) > MAX_BYTES:
            open(LOG_FILE, "w").close()
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            for _ in range(random.randint(1, 4)):
                f.write(json.dumps(build_event(spike), ensure_ascii=False) + "\n")
            if random.random() < 0.3:
                f.write(json.dumps(healthcheck_event()) + "\n")
        time.sleep(1)


if __name__ == "__main__":
    main()
