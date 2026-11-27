# Kong Gateway with Docker Compose

Run a self-managed Kong Gateway Enterprise 3.16.0.3 instance with PostgreSQL and Kong Manager. The Kong image tag and database bootstrap sequence follow the [official Docker Compose guide](https://developer.konghq.com/gateway/install/docker/).

## Quick start

For a new installation, install Docker with the Docker Compose v2 plugin, then run:

```sh
cp default.env .env
./quick-start.sh
```

Set `POSTGRES_PASSWORD` in `.env` before starting a shared deployment. To enable configuration changes through the Admin API and Kong Manager, export a valid Enterprise license before starting:

```sh
export KONG_LICENSE_DATA="$(cat /path/to/license.json)"
./quick-start.sh
```

Without a license, Kong Gateway Enterprise 3.15 and later allow read-only access to Gateway entities through the Admin API. See the [3.15 release notes](https://developer.konghq.com/gateway/changelog/#31500) and [license documentation](https://developer.konghq.com/gateway/entities/license/).

Compose waits for PostgreSQL, initializes the Kong schema, and starts the Gateway after the bootstrap job succeeds. You can also use `docker compose up -d` directly.

| Endpoint | Default address | Host port setting |
| --- | --- | --- |
| Proxy HTTP | `http://127.0.0.1` | `KONG_PROXY_HTTP_PORT` |
| Proxy HTTPS | `https://127.0.0.1` | `KONG_PROXY_HTTPS_PORT` |
| Admin API | `http://127.0.0.1:8001` | `KONG_ADMIN_PORT` |
| Kong Manager | `http://127.0.0.1:8002` | `KONG_MANAGER_PORT` |

Check the Admin API with `curl --fail http://127.0.0.1:8001/`. Use `docker compose ps -a` and `docker compose logs kong-database kong-bootstrap kong` to troubleshoot startup.

The proxy is published on host ports 80 and 443. PostgreSQL stays on the Compose network, and the Admin API and Kong Manager bind to loopback. To reach both admin interfaces on a remote host with the default ports, use an SSH tunnel:

```sh
ssh -N -L 8001:127.0.0.1:8001 -L 8002:127.0.0.1:8002 user@kong.example.com
```

For shared deployments, see Kong's guides to [securing the Admin API](https://developer.konghq.com/gateway/secure-the-admin-api/) and [setting up Kong Manager authentication](https://developer.konghq.com/gateway/kong-manager/configuration/#enable-authentication).

## Configuration and data

- `KONG_VERSION` selects the tag for both the Gateway and its bootstrap job.
- `POSTGRES_VERSION` defaults to `17-alpine`. PostgreSQL 17 is [supported by Kong Gateway 3.16](https://developer.konghq.com/gateway/third-party-support/) and retains the existing `/var/lib/postgresql/data` mount. PostgreSQL 18 uses a different default [volume layout](https://hub.docker.com/_/postgres).
- `POSTGRES_USER`, `POSTGRES_DB`, and `POSTGRES_PASSWORD` configure both PostgreSQL and Kong's connection. Set `KONG_PG_HOST` to override the database host.
- Set `KONG_TRUSTED_IPS` to the IPs or CIDRs of trusted reverse proxies if Kong receives forwarded client IP headers.

`docker compose down` stops the stack. The PostgreSQL files stay in `./pg_data`.

## Upgrading an existing installation

1. Keep a copy of the existing Compose configuration and `.env`. Identify the Kong edition and version, PostgreSQL major version, and database credentials in use. Back up PostgreSQL and the Gateway configuration. [Kong backup and restore guide](https://developer.konghq.com/gateway/upgrade/backup-and-restore/)
2. If you used the old `kong:<tag>` OSS image, follow Kong's OSS-to-Enterprise migration at a matching version first. Then use the supported Kong Gateway upgrade path, including any intermediate releases and schema migrations. The bootstrap job is for fresh databases. [OSS-to-Enterprise migration](https://developer.konghq.com/gateway/upgrade/migrate-oss-to-ee/) · [Kong Gateway upgrade guide](https://developer.konghq.com/gateway/upgrade/)
3. Check PostgreSQL compatibility at each Kong upgrade step. Keep the PostgreSQL image on the major version of the data in `./pg_data` until you migrate PostgreSQL itself. For example, moving from PostgreSQL 13 to 17 requires a major-version upgrade. [PostgreSQL major upgrade guide](https://www.postgresql.org/docs/17/upgrading.html)
4. After the schema migrations, set `KONG_VERSION=3.16.0.3` in your existing `.env` before starting this stack. Keep your database credentials and select the `POSTGRES_VERSION` that matches the migrated data.

Kong Manager replaces Konga. After you verify the migrated configuration and retire the old Konga container, open Kong Manager on port 8002.

See the [Admin API reference](https://developer.konghq.com/admin-api/) for current endpoints and examples.
