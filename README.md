# Stack de Observabilidad Open Source — Práctica Final Integradora

Prometheus · Node Exporter · SNMP Exporter · Loki · Promtail · Grafana · OpenTelemetry Collector · Jaeger

```powershell
docker compose up -d --build
powershell -ExecutionPolicy Bypass -File scripts\validar.ps1
```

| Servicio | URL |
|---|---|
| Grafana (admin/admin) | http://localhost:3000 |
| Prometheus | http://localhost:9090 |
| Jaeger | http://localhost:16686 |
| HotROD | http://localhost:8080 |
| Webhook (avisos) | http://localhost:5001 |

Forzar la alerta de CPU: `docker compose --profile stress up -d cpu-stress` (detener con `docker compose --profile stress stop cpu-stress`).

El informe técnico completo está en [INFORME.md](INFORME.md).
