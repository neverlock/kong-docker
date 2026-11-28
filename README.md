# Kong Gateway Community Edition with Docker Compose

Run Kong Gateway Community Edition 3.9.5 with PostgreSQL and the bundled Kong Manager OSS dashboard. Both the gateway and the dashboard are free and open source and require no Enterprise license. [Kong 3.9.5 release](https://github.com/Kong/kong/releases/tag/3.9.5) · [Kong Manager OSS](https://github.com/Kong/kong-manager)

## Quick start

Install Docker with the Docker Compose v2 plugin. For a new installation, copy the example settings, then start the stack.

```sh
cp default.env .env
./quick-start.sh
```

Set a unique `POSTGRES_PASSWORD` in `.env` before starting a shared deployment. Compose waits for PostgreSQL, initializes the Kong schema, and starts the Gateway after the bootstrap job succeeds. To start in the background, run `docker compose up -d`.

| Endpoint | Default address | Host port setting |
| --- | --- | --- |
| Proxy HTTP | `http://127.0.0.1` | `KONG_PROXY_HTTP_PORT` |
| Proxy HTTPS | `https://127.0.0.1` | `KONG_PROXY_HTTPS_PORT` |
| Admin API | `http://127.0.0.1:8001` | `KONG_ADMIN_PORT` |
| Kong Manager OSS | `http://127.0.0.1:8002` | `KONG_MANAGER_PORT` |

If port 8002 is in use, set `KONG_MANAGER_PORT=18002` in `.env` and open `http://127.0.0.1:18002`. If you also change `KONG_ADMIN_PORT`, the dashboard uses the updated Admin API port automatically.

## Use the dashboard

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

If startup fails, check `docker compose ps -a` and `docker compose logs kong-database kong-bootstrap kong`.

## Configuration and data

- `KONG_CE_VERSION` selects the `kong` image tag for both the Gateway and its bootstrap job. This replaces the previous Enterprise setting `KONG_VERSION`.
- `POSTGRES_VERSION` defaults to `17-alpine`. `POSTGRES_DATA_DIR` defaults to `./kong_ce_data`. Use a relative path that starts with `./` or an absolute path for a different directory.
- `POSTGRES_USER`, `POSTGRES_DB`, and `POSTGRES_PASSWORD` configure both PostgreSQL and Kong's connection. `KONG_PG_HOST` can override the default database host, `kong-database`.
- Set `KONG_TRUSTED_IPS` to the IP addresses or CIDRs of trusted reverse proxies if Kong receives forwarded client IP headers.

`docker compose down` stops the stack. The PostgreSQL files stay in the configured data directory.

## Move an existing installation

Keep a copy of your existing Compose file and `.env`, and back up the database and Gateway configuration before switching. Review any `KONG_PG_HOST` override to confirm it points to the intended CE database. [Kong backup guide](https://developer.konghq.com/gateway/upgrade/backup-and-restore/)

- **From Enterprise:** Keep the existing `./pg_data` for Enterprise. On the same Docker host, stop the Enterprise stack before starting CE so the named containers are available. Start with the new `default.env` and clear any old `KONG_PG_HOST` from your shell and `.env` unless it points to a separate CE database. Start CE with a fresh database in `./kong_ce_data` and recreate or import configuration supported by CE, such as Services, Routes, and compatible plugins. Enterprise schemas cannot be downgraded in place to CE.
- **From an older Community Edition:** Follow the upgrade steps for your current Kong version and PostgreSQL major version before reusing an existing database. Point `POSTGRES_DATA_DIR` at that directory once the schema is compatible with Kong 3.9.5, and set `POSTGRES_VERSION` to match the PostgreSQL data. For example, PostgreSQL 13 data requires a major upgrade before PostgreSQL 17 can use it. [Kong OSS upgrade guide](https://github.com/Kong/kong/blob/3.9.5/UPGRADE.md) · [PostgreSQL major upgrades](https://www.postgresql.org/docs/17/upgrading.html)

If you previously used Konga, open Kong Manager OSS on port 8002 to manage CE.

See the [Kong Admin API reference](https://developer.konghq.com/admin-api/) for endpoint documentation.
