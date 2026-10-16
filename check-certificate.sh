#!/bin/bash

CERT_FILE="/etc/letsencrypt/live/graphcert.cede-apps.ch/fullchain.pem"
HOST_NAME="graphdash.graphcert.cede-apps.ch"

echo
echo "GraphDash certificate check"
echo

disk=$(openssl x509 -in "$CERT_FILE" -noout -enddate | cut -d= -f2-)

check_port() {
    echo | openssl s_client \
        -connect localhost:"$1" \
        -servername "$HOST_NAME" 2>/dev/null |
        openssl x509 -noout -enddate 2>/dev/null |
        cut -d= -f2-
}

# Dashy is TLS-terminated by the edge reverse proxy (graphregistry-nginx)
# on 443, which serves the same certificate for the Dashy hostname.
dashy=$(check_port 443)
grafana=$(check_port 9444)
prometheus=$(check_port 9445)
infisical=$(check_port 9446)

echo "Dashy:      $dashy"
echo "Grafana:    $grafana"
echo "Prometheus: $prometheus"
echo "Infisical:  $infisical"
echo "Disk:       $disk"
echo

failed=0

[ "$dashy" != "$disk" ] && echo "❌ Dashy is NOT using the current certificate." && failed=1
[ "$grafana" != "$disk" ] && echo "❌ Grafana is NOT using the current certificate." && failed=1
[ "$prometheus" != "$disk" ] && echo "❌ Prometheus is NOT using the current certificate." && failed=1
[ "$infisical" != "$disk" ] && echo "❌ Infisical is NOT using the current certificate." && failed=1

if [ "$failed" -eq 0 ]; then
    echo "✅ GraphDash is using the current certificate on all HTTPS endpoints."
fi

echo
exit "$failed"
