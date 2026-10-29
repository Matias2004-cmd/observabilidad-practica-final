FROM alpine:3.20

# net-snmp = demonio snmpd; net-snmp-tools = snmpwalk/snmpget para pruebas
RUN apk add --no-cache net-snmp net-snmp-tools

COPY snmpd.conf /etc/snmp/snmpd.conf
COPY entrypoint.sh /entrypoint.sh
# Quita CRLF por si el repo se clonó en Windows
RUN sed -i 's/\r$//' /entrypoint.sh /etc/snmp/snmpd.conf && chmod +x /entrypoint.sh

EXPOSE 161/udp
ENTRYPOINT ["/entrypoint.sh"]
