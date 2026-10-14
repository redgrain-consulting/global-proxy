#!/usr/bin/env bash
#
# dev-up.sh — start the Caffè Nero dev stack inside Apple Containers.
#
# After a reboot, Orchard / `container start` only *boots* the containers. The
# daemons come from each devcontainer's postStartCommand and the dev servers from
# VS Code folderOpen tasks, and neither runs unless VS Code attaches. The result
# is containers with nothing listening, so https://*.dev.redgrain.co.uk fails at
# connect (HTTP 000). This script is the single "start everything" entry point.
#
# Idempotent: every step checks first, so it is safe to re-run at any time.
#
# Usage:  ./scripts/dev-up.sh
#
# See README.md for the one-time container.acm DNS setup this depends on.

set -uo pipefail

# The `container` CLI lives in Homebrew, which a GUI or launchd PATH may omit.
if ! command -v container >/dev/null 2>&1; then
  PATH="/opt/homebrew/bin:$PATH"
  export PATH
fi

PROXY=global-proxy
STATAMIC=caffenero-statamic
CATALYST=caffenero-catalyst

running() { container ls --quiet 2>/dev/null | grep -qx "$1"; }

# 1. Container system --------------------------------------------------------
if ! container system status 2>/dev/null | grep -q '^status *running'; then
  echo "==> Starting the container system"
  container system start
fi

# 2. Containers --------------------------------------------------------------
# Proxy last, so its upstreams exist (and resolve) before Caddy starts.
for c in "$STATAMIC" "$CATALYST" "$PROXY"; do
  if running "$c"; then
    echo "==> $c already running"
  else
    echo "==> Starting $c"
    container start "$c" || echo "    (could not start $c — has it been created?)"
  fi
done

# 2b. Builder ----------------------------------------------------------------
# The builder VM reserves 4 GB, and the three app containers reserve 13 GB of
# this 16 GB host — with the builder up that overcommits and a container VM can
# lock up (an unresponsive guest that stop/kill/rm all refuse). `container build`
# starts it again on demand, so it does not need to linger.
if container ls --quiet 2>/dev/null | grep -qx buildkit; then
  echo "==> Stopping the builder (frees 4 GB; restarts on the next build)"
  container builder stop >/dev/null 2>&1
fi

# 3. Daemons (normally postStartCommand) -------------------------------------
echo "==> $PROXY: sshd + caddy + log-prettifier"
container exec "$PROXY" bash /workspaces/global-proxy/.appcontainer/start.sh >/dev/null 2>&1

echo "==> $STATAMIC: sshd + php-fpm + nginx"
container exec "$STATAMIC" sh -c '
  mkdir -p /run/sshd
  kill -0 "$(cat /run/sshd.pid 2>/dev/null)" 2>/dev/null || /usr/sbin/sshd
  pgrep -x php-fpm >/dev/null 2>&1 || /usr/local/sbin/php-fpm --nodaemonize --allow-to-run-as-root >/tmp/php-fpm.log 2>&1 &
  pgrep -x nginx   >/dev/null 2>&1 || /usr/sbin/nginx -g "daemon off;" >/tmp/nginx.log 2>&1 &
' >/dev/null 2>&1

echo "==> $CATALYST: sshd"
container exec "$CATALYST" sh -c '
  mkdir -p /run/sshd
  kill -0 "$(cat /run/sshd.pid 2>/dev/null)" 2>/dev/null || /usr/sbin/sshd
' >/dev/null 2>&1

# 4. Dev servers (normally folderOpen tasks) ---------------------------------
# The brackets stop pgrep matching the shell that runs it.
echo "==> $STATAMIC: control-panel vite"
container exec "$STATAMIC" sh -c '
  pgrep -f "vite --config vite-c[p]" >/dev/null 2>&1 && exit 0
  cd /workspaces/caffenero-statamic
  nohup pnpm cp:dev >/tmp/vite-cp.log 2>&1 </dev/null &
' >/dev/null 2>&1

echo "==> $CATALYST: next dev"
container exec "$CATALYST" sh -c '
  pgrep -f "next de[v]" >/dev/null 2>&1 && exit 0
  cd /workspaces/caffenero-catalyst
  nohup pnpm dev >/tmp/next-dev.log 2>&1 </dev/null &
' >/dev/null 2>&1

# 5. Wait for the proxy to answer --------------------------------------------
echo
echo "==> Waiting for the sites..."
for h in "$CATALYST" "$STATAMIC"; do
  code=000
  for _ in $(seq 1 60); do
    code=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 5 "https://$h.dev.redgrain.co.uk/" 2>/dev/null) || code=000
    [ "$code" = "200" ] && break
    sleep 2
  done
  printf '  https://%s.dev.redgrain.co.uk/ -> HTTP %s\n' "$h" "$code"
done
