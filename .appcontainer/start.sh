#!/usr/bin/env bash
# Runs as postStartCommand. The extension overrides CMD with its own keep-alive,
# so sshd, Caddy and the log prettifier are all started here.
#
# Idempotent: the extension re-runs postStartCommand on every apply, and a
# second sshd/caddy would fail to bind and fail the whole apply. Every service
# runs in the background with output redirected rather than daemonising: a
# process that inherits the exec's stdout makes `container exec` hang, which
# would stall the apply.
set -uo pipefail

WORKSPACE=/workspaces/global-proxy

# The Caddyfile reads certs and writes logs at the paths the compose file
# mounted them on; point those at the bind-mounted repo instead.
mkdir -p "$WORKSPACE/logs" /etc/caddy /data
ln -sfn "$WORKSPACE/certs" /etc/caddy/certs
ln -sfn "$WORKSPACE/logs" /data/logs

mkdir -p /run/sshd
kill -0 "$(cat /run/sshd.pid 2>/dev/null)" 2>/dev/null || /usr/sbin/sshd

# --watch reloads on Caddyfile edits (it polls, so it works over virtiofs).
if ! pgrep -x caddy >/dev/null 2>&1; then
  nohup caddy run --config "$WORKSPACE/Caddyfile" --adapter caddyfile --watch \
    >/tmp/caddy.log 2>&1 </dev/null &
fi

if ! pgrep -f log-prettifier.sh >/dev/null 2>&1; then
  nohup bash "$WORKSPACE/.appcontainer/log-prettifier.sh" \
    >/tmp/log-prettifier.log 2>&1 </dev/null &
fi

exit 0
