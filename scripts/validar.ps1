# Valida cada componente del stack consultando sus APIs HTTP.
# Uso (desde la carpeta del proyecto):  powershell -ExecutionPolicy Bypass -File scripts\validar.ps1
# Si se cambiaron las credenciales de Grafana, definir antes de ejecutarlo:
#   $env:GRAFANA_USER = "..."; $env:GRAFANA_PASSWORD = "..."

$ErrorActionPreference = "Continue"
$grafanaUser = if ($env:GRAFANA_USER) { $env:GRAFANA_USER } else { "admin" }
$grafanaPass = if ($env:GRAFANA_PASSWORD) { $env:GRAFANA_PASSWORD } else { "admin" }
$auth = @{ Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${grafanaUser}:$grafanaPass")) }

function Titulo($t) { Write-Host ""; Write-Host "=== $t ===" -ForegroundColor Cyan }
function Ok($t)     { Write-Host "  [OK]    $t" -ForegroundColor Green }
function Falla($t)  { Write-Host "  [FALLA] $t" -ForegroundColor Red }

function PromQL($q) {
    $u = "http://localhost:9090/api/v1/query?query=" + [uri]::EscapeDataString($q)
    return (Invoke-RestMethod -Uri $u).data.result
}

Titulo "1. Contenedores"
docker compose ps --format "table {{.Name}}\t{{.State}}\t{{.Status}}"

Titulo "2. Prometheus - estado de los targets"
try {
    $targets = (Invoke-RestMethod "http://localhost:9090/api/v1/targets").data.activeTargets
    foreach ($t in $targets) {
        $msg = "{0,-18} {1,-28} {2}" -f $t.labels.job, $t.labels.instance, $t.health
        if ($t.health -eq "up") { Ok $msg } else { Falla "$msg  $($t.lastError)" }
    }
} catch { Falla "Prometheus no responde: $_" }

Titulo "3. PromQL - uso de CPU (%)"
try {
    foreach ($r in PromQL '100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[1m])) * 100)') {
        Ok ("CPU {0}: {1:N2} %" -f $r.metric.instance, [double]$r.value[1])
    }
} catch { Falla $_ }

Titulo "4. PromQL - ancho de banda SNMP (Mbps)"
try {
    $res = PromQL 'rate(ifHCInOctets{job="snmp"}[1m]) * 8 / 1000000'
    if (-not $res) { Falla "Sin datos aun (espera ~1 minuto tras levantar el stack)" }
    foreach ($r in $res) { Ok ("{0,-6} entrada: {1:N3} Mbps" -f $r.metric.ifName, [double]$r.value[1]) }
} catch { Falla $_ }

Titulo "5. snmp_exporter consultando al agente SNMP"
try {
    $snmp = Invoke-WebRequest -UseBasicParsing "http://localhost:9116/snmp?target=snmp-agent:161&module=if_mib&auth=public_v2"
    $lineas = ($snmp.Content -split "`n") | Where-Object { $_ -match '^ifHCInOctets' }
    if ($lineas) { $lineas | ForEach-Object { Ok $_ } } else { Falla "No se encontro ifHCInOctets" }
} catch { Falla $_ }

Titulo "6. Loki - valores de la etiqueta 'level' indexada por Promtail"
try {
    $levels = (Invoke-RestMethod "http://localhost:3100/loki/api/v1/label/level/values").data
    if ($levels) { Ok ("level = " + ($levels -join ", ")) } else { Falla "Aun no hay logs" }
    $q = [uri]::EscapeDataString('sum by (level) (count_over_time({job="cloud-app"}[5m]))')
    foreach ($r in (Invoke-RestMethod "http://localhost:3100/loki/api/v1/query?query=$q").data.result) {
        Ok ("{0,-9} {1} lineas en 5 min" -f $r.metric.level, $r.value[1])
    }
} catch { Falla $_ }

Titulo "7. Jaeger - servicios que reportan trazas"
try {
    $svcs = (Invoke-RestMethod "http://localhost:16686/api/services").data
    if ($svcs) { Ok ("servicios = " + ($svcs -join ", ")) } else { Falla "Sin trazas aun" }
} catch { Falla $_ }

Titulo "8. Grafana - datasources, dashboard y regla de alerta"
try {
    Ok ("Grafana " + (Invoke-RestMethod "http://localhost:3000/api/health").version)
    foreach ($d in (Invoke-RestMethod -Headers $auth "http://localhost:3000/api/datasources")) { Ok "datasource: $($d.name) ($($d.type))" }
    $db = Invoke-RestMethod -Headers $auth "http://localhost:3000/api/dashboards/uid/dashboard-operativo"
    Ok ("dashboard: {0} ({1} paneles)" -f $db.dashboard.title, $db.dashboard.panels.Count)
    foreach ($r in (Invoke-RestMethod -Headers $auth "http://localhost:3000/api/v1/provisioning/alert-rules")) { Ok "regla de alerta: $($r.title)" }
    $estado = Invoke-RestMethod -Headers $auth "http://localhost:3000/api/prometheus/grafana/api/v1/rules"
    foreach ($g in $estado.data.groups) { foreach ($r in $g.rules) { Ok "estado de '$($r.name)': $($r.state)" } }
} catch { Falla $_ }

Titulo "9. Webhook receiver - avisos recibidos"
try {
    $w = Invoke-RestMethod "http://localhost:5001/"
    Ok "avisos recibidos: $($w.total)"
} catch { Falla $_ }

Write-Host ""
