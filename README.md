# Global Dev Proxy

A single Caddy container that terminates TLS for every `*.dev.redgrain.co.uk`
site and reverse-proxies it to the matching app container.

## Prerequisites

Copy the relevant files into place at [certs/redgrain.co.uk.crt](./certs/redgrain.co.uk.crt),
[certs/redgrain.co.uk.fullchain.crt](./certs/redgrain.co.uk.fullchain.crt) and
[certs/redgrain.co.uk.key](./certs/redgrain.co.uk.key) — you will need to ask for
these to be provided.

## Start (Apple Container)

The proxy is a normal container defined by [compose.yaml](./compose.yaml) — two
services (Caddy and a log prettifier) built from [Dockerfile](./Dockerfile). Bring
it up with the `container` CLI or from Orchard's **Compose** tab:

```bash
container compose up
```

`container compose up --dry-run` prints the plan without changing anything, and
`container compose down` stops and removes it again. Caddy reloads automatically
when the `Caddyfile` changes.

The log prettifier tails each site's JSON access log from `logs/*.log` into a
one-line-per-request `logs/*.formatted.log`.

> **Note on filename precedence.** Docker Compose and the `container compose`
> plugin both look for `compose.yaml` first, then `docker-compose.yml`. The legacy
> Docker setup is still in [docker-compose.yml](./docker-compose.yml); bring it up
> explicitly with `docker compose -f docker-compose.yml up -d`.

### One-time DNS setup

Create the DNS domain so Caddy can reach the app containers by name:

```bash
sudo container system dns create container.acm
```

Then set it as the default domain in `~/.config/container/config.toml` (container
1.5.0 has no `property set` command):

```toml
[dns]
domain = "container.acm"
```

Restart the container system to load both. This stops all running containers.

```bash
container system stop && container system start
```

> **Port 53 must be free on the host.** Apple serves DNS to the containers from
> macOS's `mDNSResponder`, which binds the wildcard `*:53`. If another resolver
> already holds port 53 — `dnsmasq`, Zscaler, etc. — that bind fails, the vmnet
> gateway (192.168.64.1) ends up with nothing listening, and every container gets
> `ECONNREFUSED` for DNS (public names *and* `<name>.container.acm`). Check with
> `sudo lsof -i :53` and stop the offender, e.g.
> `sudo launchctl bootout system/homebrew.mxcl.dnsmasq`. See
> [apple/container#402](https://github.com/apple/container/issues/402).

Then:

1. Rebuild each app container (catalyst, statamic and the rest) so it registers as
   `<name>.container.acm`.
2. Point each app at its dependencies by container name. For catalyst, set
   `NEXT_PUBLIC_STATAMIC_GRAPHQL_API_URL=http://caffenero-statamic.container.acm/graphql`
   in `.env.local`; the old `http://192.168.64.1:8080/graphql` assumed Statamic's
   nginx was published on the host.
3. Bring the proxy up with `container compose up`.

Caddy is on Apple Container's built-in `default` network, the same one the app
containers use, because a container joins only one network and can only reach
services on its own. Its output goes to `container logs global-proxy`.

## Add/Edit A Site

See `# --- Site Blocks ---` in the [Caddyfile](./Caddyfile)

## Configuring A Host

Make sure to replace `<SITENAME>` with the actual site name with one the following methods:

### Adding A Site Hostname Via Script
Run the following command on the host system to configure the site to be served on <SITENAME>.dev.redgrain.co.uk:
`sudo bash -c 'echo "127.0.0.1 <SITENAME>.dev.redgrain.co.uk" >> /etc/hosts'`

### Adding A Site Hostname Manually
Add `127.0.0.1 <SITENAME>.dev.redgrain.co.uk` to `/etc/hosts` on the host system.
