# Docker Proxy For Dev Containers

## Prerequisites
Copy the relevant files into place at [certs/redgrain.co.uk.crt](./certs/redgrain.co.uk.crt), [certs/redgrain.co.uk.fullchain.crt](./certs/redgrain.co.uk.fullchain.crt) and [certs/redgrain.co.uk.key](./certs/redgrain.co.uk.key) - you will need to ask for these to be provided.

## Start
`docker compose up -d`

### Apple Container (VS Code)
Uses the [Apple Container Manager](https://marketplace.visualstudio.com/items?itemName=Awei-Sumaho.apple-container-manager) extension and `.appcontainer/`. Caddy and the log prettifier run in a single container that publishes 80, 443 (TCP and UDP) and 6006, plus 2224 for SSH.

1. One-time setup: create the DNS domain so Caddy can reach the other containers by name. Don't use the extension's **Initialize DNS** command: it runs `container system property set`, which 1.5.0 removed.
   ```bash
   sudo container system dns create container.acm
   ```
   Then set it as the default domain in `~/.config/container/config.toml` (container 1.5.0 has no `property set` command):
   ```toml
   [dns]
   domain = "container.acm"
   ```
   Restart the container system to load both. This stops all running containers.
   ```bash
   container system stop && container system start
   ```

   > **Port 53 must be free on the host.** Apple serves DNS to the containers
   > from macOS's `mDNSResponder`, which binds the wildcard `*:53`. If another
   > resolver already holds port 53 — `dnsmasq`, Zscaler, etc. — that bind fails,
   > the vmnet gateway (192.168.64.1) ends up with nothing listening, and every
   > container gets `ECONNREFUSED` for DNS (public names *and*
   > `<name>.container.acm`). Check with `sudo lsof -i :53` and stop the offender,
   > e.g. `sudo launchctl bootout system/homebrew.mxcl.dnsmasq`. See
   > [apple/container#402](https://github.com/apple/container/issues/402).

2. Rebuild each app container (catalyst, statamic and the rest) so it registers as `<name>.container.acm`.
3. Point each app at its dependencies by container name. For catalyst, set
   `NEXT_PUBLIC_STATAMIC_GRAPHQL_API_URL=http://caffenero-statamic.container.acm/graphql`
   in `.env.local`; the old `http://192.168.64.1:8080/graphql` assumed Statamic's
   nginx was published on the host.
4. Open this folder in VS Code and run **Apple Container: Reopen Folder in Container**.

Caddy reloads automatically when the `Caddyfile` changes. Its output is in `/tmp/caddy.log` inside the container.

## Add/Edit A Site
See `# --- Site Blocks ---` in the [Caddyfile](./Caddyfile)

## Configuring A Host
Make sure to replace `<SITENAME>` with the actual site name with one the following methods:

### Adding A Site Hostname Via Script
Run the following command on the host system to configure the site to be served on <SITENAME>.dev.redgrain.co.uk:
`sudo bash -c 'echo "127.0.0.1 <SITENAME>.dev.redgrain.co.uk" >> /etc/hosts'`

### Adding A Site Hostname Manually
Add `127.0.0.1 <SITENAME>.dev.redgrain.co.uk` to `/etc/hosts` on the host system.