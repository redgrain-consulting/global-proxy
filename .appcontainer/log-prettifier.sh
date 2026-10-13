#!/usr/bin/env bash
# The log-prettifier compose service, run alongside Caddy in the same container.
# Tails each Caddy JSON access log into a one-line-per-request *.formatted.log.
set -u

LOGS=/workspaces/global-proxy/logs

rm -f "$LOGS"/*.formatted.log
for f in "$LOGS"/*.log; do
  [ -e "$f" ] || continue
  tail -n +1 -F "$f" | jq --unbuffered -R -r '
    fromjson? | select(.status != null) |
    "[\(.ts | floor | strftime("%H:%M:%S"))] [\(.level | ascii_upcase)] \(.status) \(.request.method) \(.request.host)\(.request.uri) [\(.request.client_ip)] (\((.duration * 1000) | floor)ms) \(.request.proto)"
  ' >> "${f%.log}.formatted.log" &
done
wait
