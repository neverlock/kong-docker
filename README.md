# Kong Gateway Community Edition with Docker Compose

Run Kong Gateway Community Edition 3.9.5 with PostgreSQL and the bundled Kong Manager OSS dashboard. Both the gateway and the dashboard are free and open source and require no Enterprise license. [Kong 3.9.5 release](https://github.com/Kong/kong/releases/tag/3.9.5) · [Kong Manager OSS](https://github.com/Kong/kong-manager)

## Quick start

Install Docker with the Docker Compose v2 plugin. For a new installation, copy the example settings, then start the stack.

```sh
cp default.env .env
./quick-start.sh
```

Set a unique `POSTGRES_PASSWORD` in `.env` before starting a shared deployment. The script starts Kong CE with Kong Manager and Konga in the background. It waits for PostgreSQL and the Kong schema bootstrap, then waits for Kong and Konga to become healthy and prints their status.

To start both dashboards directly, run `docker compose --profile konga up -d --wait`. To start the default Compose services with Kong CE and Kong Manager, run `docker compose up -d --wait`.

| Endpoint | Default address | Host port setting |
| --- | --- | --- |
| Proxy HTTP | `http://127.0.0.1` | `KONG_PROXY_HTTP_PORT` |
| Proxy HTTPS | `https://127.0.0.1` | `KONG_PROXY_HTTPS_PORT` |
| Admin API | `http://127.0.0.1:8001` | `KONG_ADMIN_PORT` |
| Kong Manager OSS | `http://127.0.0.1:8002` | `KONG_MANAGER_PORT` |
| Konga | `http://127.0.0.1:1337` | `KONGA_PORT` |

If port 8002 is in use, set `KONG_MANAGER_PORT=18002` in `.env` and open `http://127.0.0.1:18002`. If you also change `KONG_ADMIN_PORT`, the dashboard uses the updated Admin API port automatically.

## Use Kong Manager

1. Open [Kong Manager](http://127.0.0.1:8002) in your browser.
2. Open **Gateway Services**, create a service named `example` with URL `https://example.com`, and save it.
3. Confirm that the service appears in the dashboard and in the Admin API.

   ```sh
   curl --fail http://127.0.0.1:8001/services/example
   ```

The dashboard and Admin API bind to loopback and have no application login in this setup. Keep both ports private. To access them on a remote host using the default ports, open an SSH tunnel and visit the same local addresses.

```sh
ssh -N -L 8001:127.0.0.1:8001 -L 8002:127.0.0.1:8002 user@kong.example.com
```

The proxy publishes ports 80 and 443 on the host. PostgreSQL stays inside the Compose network.

If quick start fails, check `docker compose --profile konga ps -a` and `docker compose --profile konga logs kong-database kong-bootstrap kong konga`.

## Use Konga

1. Open [Konga](http://127.0.0.1:1337), create the initial admin account, and sign in.
2. Add a connection with type **Default**, name it `kong`, and use `http://kong:8001` as the **Kong Admin URL**.
3. Save and activate the connection.

Konga listens on loopback. If port 1337 is in use, set `KONGA_PORT=11337` in `.env` and open `http://127.0.0.1:11337`. The Kong Admin URL inside Konga stays `http://kong:8001`. For remote access with the default port, forward it over SSH.

```sh
ssh -N -L 1337:127.0.0.1:1337 user@kong.example.com
```

The `konga_data` Docker volume keeps the Konga account, connections, and generated session signing secret between restarts. The image is published for Linux AMD64, so ARM hosts need AMD64 emulation. [Konga image tags](https://hub.docker.com/r/pantsel/konga/tags)

Konga is archived and documents compatibility with Kong 1.x. Keep this profile for local development and use Kong Manager for features that Konga cannot manage on Kong 3.9. [Konga compatibility](https://github.com/pantsel/konga#compatibility)

## Configuration and data

- `KONG_CE_VERSION` selects the `kong` image tag for both the Gateway and its bootstrap job. This replaces the previous Enterprise setting `KONG_VERSION`.
- `POSTGRES_VERSION` defaults to `17-alpine`. `POSTGRES_DATA_DIR` defaults to `./kong_ce_data`. Use a relative path that starts with `./` or an absolute path for a different directory.
- `POSTGRES_USER`, `POSTGRES_DB`, and `POSTGRES_PASSWORD` configure both PostgreSQL and Kong's connection. `KONG_PG_HOST` can override the default database host, `kong-database`.
- Set `KONG_TRUSTED_IPS` to the IP addresses or CIDRs of trusted reverse proxies if Kong receives forwarded client IP headers.

Run `docker compose --profile konga down` to stop the full quick-start stack. Run `docker compose down` if you started only the default Compose services. To stop only Konga, run `docker compose stop konga`. The PostgreSQL data directory and Konga volume persist.

## Move an existing installation

Keep a copy of your existing Compose file and `.env`, and back up the database and Gateway configuration before switching. Review any `KONG_PG_HOST` override to confirm it points to the intended CE database. [Kong backup guide](https://developer.konghq.com/gateway/upgrade/backup-and-restore/)

- **From Enterprise:** Keep the existing `./pg_data` for Enterprise. On the same Docker host, stop the Enterprise stack before starting CE so the named containers are available. Start with the new `default.env` and clear any old `KONG_PG_HOST` from your shell and `.env` unless it points to a separate CE database. Start CE with a fresh database in `./kong_ce_data` and recreate or import configuration supported by CE, such as Services, Routes, and compatible plugins. Enterprise schemas cannot be downgraded in place to CE.
- **From an older Community Edition:** Follow the upgrade steps for your current Kong version and PostgreSQL major version before reusing an existing database. Point `POSTGRES_DATA_DIR` at that directory once the schema is compatible with Kong 3.9.5, and set `POSTGRES_VERSION` to match the PostgreSQL data. For example, PostgreSQL 13 data requires a major upgrade before PostgreSQL 17 can use it. [Kong OSS upgrade guide](https://github.com/Kong/kong/blob/3.9.5/UPGRADE.md) · [PostgreSQL major upgrades](https://www.postgresql.org/docs/17/upgrading.html)

See the [Kong Admin API reference](https://developer.konghq.com/admin-api/) for endpoint documentation.
