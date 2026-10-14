#!/usr/bin/env bash
# Container CMD. Starts Caddy (plus sshd and the log prettifier via start.sh) only
# when autostart is enabled, then keeps the container alive — so a plain
# `container start` (e.g. from Orchard) is enough, and each user decides whether
# their container autostarts.
#
# Autostart is on when either:
#   - the container environment has DEV_AUTOSTART=true, or
#   - the repo's own .env sets DEV_AUTOSTART=true.
# The file route is per-user (it is gitignored) and needs no image rebuild.
#
# The VS Code extension overrides CMD with its own keep-alive and runs start.sh
# from devcontainer.json's postStartCommand, so this path is only used when the
# container is started outside the extension. start.sh is idempotent.
set -uo pipefail

WORKSPACE=/workspaces/global-proxy

# Print KEY from an env file: last value wins, surrounding whitespace/quotes
# stripped. Missing file or key prints nothing.
read_env() {
  [ -f "$1" ] || return 0
  sed -n "s/^[[:space:]]*$2[[:space:]]*=//p" "$1" | tail -1 \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
          -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//"
}

autostart="${DEV_AUTOSTART:-}"
[ -n "$autostart" ] || autostart="$(read_env "$WORKSPACE/.env" DEV_AUTOSTART)"

if [ "$autostart" = "true" ]; then
  bash "$WORKSPACE/.appcontainer/start.sh"
fi

exec sleep infinity
