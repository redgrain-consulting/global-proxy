# Caddy + log prettifier image for the Apple Container Manager dev container.
# Ported from docker-compose.yml — no compose and no devcontainer features (the
# extension does not support them), so the two compose services (caddy and
# log-prettifier) share this one container and are started by start.sh.
#
# Debian rather than caddy's own Alpine image: the extension connects over
# Remote-SSH, and the VS Code server is far better supported on glibc.
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# openssh-server: the extension injects a key into remoteUser's
#   ~/.ssh/authorized_keys and connects over Remote-SSH, so the image must ship
#   an SSH server.
# jq: the log prettifier (the old log-prettifier compose service).
# ca-certificates / curl / git / procps: VS Code server download, debugging the
#   upstreams from a terminal, and pgrep in start.sh.
# dnsutils: `dig` for checking <container>.<domain> resolution from inside.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        openssh-server \
        ca-certificates \
        curl \
        git \
        jq \
        procps \
        dnsutils \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/sshd \
    && ssh-keygen -A

COPY --from=caddy:2 /usr/bin/caddy /usr/bin/caddy

# Same paths as the official image, so the Caddyfile is unchanged between the
# compose and Apple Container setups.
ENV XDG_CONFIG_HOME=/config \
    XDG_DATA_HOME=/data
RUN mkdir -p /config /data /etc/caddy

# The extension bind-mounts the repo here (see "workspaceFolder").
WORKDIR /workspaces/global-proxy

# Start Caddy on boot when the container is opted in with DEV_AUTOSTART=true, so
# a plain `container run` / `container start` (e.g. from Orchard) needs no
# lifecycle hooks. The extension overrides CMD with its own keep-alive and runs
# start.sh from postStartCommand instead.
COPY entrypoint.sh /usr/local/bin/dev-entrypoint.sh
RUN chmod +x /usr/local/bin/dev-entrypoint.sh
CMD ["/usr/local/bin/dev-entrypoint.sh"]
