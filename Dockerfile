# Caddy + log prettifier image for the global proxy.
#
# Debian rather than caddy's own Alpine image: the two compose services share
# this one image, and the log prettifier is a bash script that needs jq. Caddy's
# binary is copied in (rather than extending caddy:2) so the image ships no
# ENTRYPOINT — the compose plugin cannot override an entrypoint, only CMD, so
# each service sets its own `command`.
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# ca-certificates: caddy talks TLS. jq: the log prettifier. bash is already in
# the Debian base and is what runs log-prettifier.sh.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        jq \
    && rm -rf /var/lib/apt/lists/*

COPY --from=caddy:2 /usr/bin/caddy /usr/bin/caddy

# Same paths as the official image, so the Caddyfile is unchanged.
ENV XDG_CONFIG_HOME=/config \
    XDG_DATA_HOME=/data
RUN mkdir -p /config /data /etc/caddy

COPY scripts/log-prettifier.sh /usr/local/bin/log-prettifier.sh
RUN chmod +x /usr/local/bin/log-prettifier.sh

WORKDIR /workspace
