# Capturas de evidencia (usadas en INFORME.md)

| Archivo | Contenido |
|---|---|
| 01-docker-compose-ps.png | Los 13 contenedores en ejecución |
| 02 / 02b-validar-ps1.png | Salida completa de `scripts\validar.ps1` |
| 03 / 03b / 03c-prometheus-targets.png | Los 8 targets de Prometheus en UP (03c: relabeling SNMP) |
| 04-promql-cpu.png | Consulta PromQL de uso de CPU (con la prueba de carga) |
| 05-snmpwalk.png | Consultas SNMP directas al agente (contador ifHCInOctets subiendo) |
| 06-promql-ancho-banda.png | Consulta PromQL de ancho de banda en Mbps |
| 07-promtail-targets.png | Promtail leyendo el log simulado |
| 08-loki-explore-level.png | Grafana Explore: etiqueta `level` indexada en Loki |
| 09-grafana-datasources.png | Datasources Prometheus, Loki y Jaeger |
| 10a a 10d-dashboard-*.png | Dashboard Operativo SRE (salud/red, storage, logs, APM) |
| 11a / 11b-alerta-*.png | Regla de CPU en Pending y en Firing |
| 12-webhook-recibido.png | JSON del aviso recibido por el webhook |
| 12b-webhook-logs.png | Log del receptor: FIRING y RESOLVED |
| 13-alerta-resuelta.png | Regla de vuelta en Normal |
| 14-jaeger-busqueda.png | Búsqueda de trazas `frontend: /dispatch` |
| 15-jaeger-traza.png | Línea de tiempo de la traza e85691c (1,58 s) |
| 16-jaeger-mysql-lock.png | Span de MySQL con el log "Waiting for lock behind 3 transactions" |
| 17-jaeger-system-architecture.png | Grafo de dependencias entre servicios |
