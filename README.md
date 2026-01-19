# Docker Proxy For Dev Containers

## Prerequisites
Copy the relevant files into place at [certs/local.crt](./certs/local.crt) and [certs/local.key](./certs/local.key) - you will need to ask for these to be provided.

## Start
`docker compose up -d`

## Add/Edit A Site
See `# --- Site Blocks ---` in the [Caddyfile](./Caddyfile)

## Configuring A Host
Make sure to replace `<SITENAME>` with the actual site name with one the following methods:

### Adding A Site Hostname Via Script
Run the following command on the host system to configure the site to be served on <SITENAME>.dev.redgrain.co.uk:
`sudo bash -c 'echo "127.0.0.1 <SITENAME>.dev.redgrain.co.uk" >> /etc/hosts'`

### Adding A Site Hostname Manually
Add `127.0.0.1 <SITENAME>.dev.redgrain.co.uk` to `/etc/hosts` on the host system.