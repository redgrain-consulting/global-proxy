#!/usr/bin/env bash
# Tails each Caddy JSON access log into a one-line-per-request *.formatted.log.
#
# Runs as its own compose service (see compose.yaml) off the image that ships
# this script, with the repo's logs/ bind-mounted at /logs.
set -u

LOGS=/logs

rm -f "$LOGS"/*.formatted.log
for f in "$LOGS"/*.log; do
  [ -e "$f" ] || continue
  tail -n +1 -F "$f" | jq --unbuffered -R -r '
    fromjson? | select(.status != null) |
    "[\(.ts | floor | strftime("%H:%M:%S"))] [\(.level | ascii_upcase)] \(.status) \(.request.method) \(.request.host)\(.request.uri) [\(.request.client_ip)] (\((.duration * 1000) | floor)ms) \(.request.proto)"
  ' >> "${f%.log}.formatted.log" &
done
wait
