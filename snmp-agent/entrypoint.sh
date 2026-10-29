#!/bin/sh
# Genera tráfico variable por eth0 descargando /metrics del node-exporter
# (~100 KB por petición) en ráfagas de 1 a 5 peticiones cada segundo.
# Así los contadores ifHCInOctets/ifHCOutOctets crecen y el ancho de banda
# en Mbps se ve en Grafana.
(
  sleep 10
  while true; do
    n=$((RANDOM % 5 + 1))
    i=0
    while [ "$i" -lt "$n" ]; do
      wget -q -O /dev/null http://node-exporter:9100/metrics
      i=$((i + 1))
    done
    sleep 1
  done
) &

# -f: primer plano, -Lo: logs a stdout, -C: solo el archivo indicado con -c
exec snmpd -f -Lo -C -c /etc/snmp/snmpd.conf
