#!/usr/bin/env bash
# The non-root hardening fix that failed every healthcheck.
# 1) .NET 8 + USER app: container healthy-looking in logs, unhealthy to the probe
#    (the probe still checks port 80; .NET 8 listens on 8080).
# 2) Same USER app line on the 6.0 base image: container won't start at all.
set -euo pipefail
cd "$(dirname "$0")"

echo "== build hardened image (aspnet:8.0, USER app, listens on 8080)"
docker build -q -f Contoso.Gateway.Api/Dockerfile -t contoso-gateway-api:hardened .

echo "== run it; the healthcheck (stale target group) probes port 80"
docker rm -f gw-demo >/dev/null 2>&1 || true
docker run -d --name gw-demo contoso-gateway-api:hardened >/dev/null
sleep 20
echo "-- health status: $(docker inspect -f '{{.State.Health.Status}}' gw-demo)"
echo "-- app log (listening on 8080 the whole time):"
docker logs gw-demo 2>&1 | grep -i 'listening' || true
docker rm -f gw-demo >/dev/null

echo
echo "== same hardening on the old base image (aspnet:6.0, no 'app' user)"
docker build -q -f Contoso.Gateway.Api/Dockerfile.legacy -t contoso-gateway-api:legacy-hardened .
docker run --rm contoso-gateway-api:legacy-hardened 2>&1 | head -2 || true

echo
echo "Fixes: probe 8080 (or set ASPNETCORE_HTTP_PORTS=80 pre-migration); create the user explicitly on old bases."
