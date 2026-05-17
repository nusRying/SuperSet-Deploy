# Apache Superset Coolify Docker Compose

[![Validate](https://github.com/nusRying/SuperSet-Deploy/actions/workflows/validate.yml/badge.svg)](https://github.com/nusRying/SuperSet-Deploy/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Apache Superset](https://img.shields.io/badge/Apache%20Superset-Docker%20Compose-blue)](https://superset.apache.org/)
[![Coolify](https://img.shields.io/badge/Coolify-ready-black)](https://coolify.io/)

Deploy Apache Superset on Coolify with Docker Compose, PostgreSQL, Redis, Celery workers, and a production-style Superset image that installs the drivers needed for this stack.

This repository is a ready-to-adapt template for self-hosting Superset behind Coolify's reverse proxy.

## Features

- Apache Superset web service on container port `8088`
- PostgreSQL metadata database
- Redis cache, Celery broker, and result backend
- Celery worker and Celery beat scheduler
- Superset startup bootstrap for migrations, role sync, and admin password reset
- Custom Superset image for Python database drivers
- Coolify-friendly Compose file with no public database or Redis ports

## Stack

| Service | Purpose |
| --- | --- |
| `superset` | Superset web app and bootstrap runner |
| `superset-worker` | Background job worker |
| `superset-worker-beat` | Scheduled job runner |
| `db` | PostgreSQL metadata database |
| `redis` | Cache and queue backend |

## Quick Start On Coolify

1. Create a new Coolify resource from this repository.
2. Select the **Docker Compose** build pack.
3. Set the Compose file path:

   ```text
   docker-compose.yml
   ```

4. Assign your domain to the `superset` service with internal port `8088`:

   ```text
   https://superset.example.com:8088
   ```

5. Leave domains blank for `db`, `redis`, `superset-worker`, and `superset-worker-beat`.
6. Deploy.

Users should open:

```text
https://superset.example.com
```

## Configuration

The Compose file includes defaults for a fast private deployment. Override these in Coolify for production:

```env
ADMIN_USERNAME=admin
ADMIN_PASSWORD=change-me
ADMIN_EMAIL=admin@example.com
POSTGRES_DB=superset
POSTGRES_USER=superset
POSTGRES_PASSWORD=change-me
POSTGRES_VERSION=16-alpine
SUPERSET_SECRET_KEY=change-me-to-a-long-random-secret
SUPERSET_LOAD_EXAMPLES=no
SUPERSET_RESET_ADMIN_PASSWORD=true
```

Add database drivers with `SUPERSET_PIP_PACKAGES`:

```env
SUPERSET_PIP_PACKAGES=psycopg2-binary redis gevent openpyxl trino sqlalchemy-bigquery clickhouse-connect
```

Do not set `SQLALCHEMY_DATABASE_URI` for the default stack. Superset builds its metadata database URL from the `POSTGRES_*` variables. Use `SUPERSET_SQLALCHEMY_DATABASE_URI` only when you intentionally use an external metadata database.

## Persistent Volumes

| Volume | Stores |
| --- | --- |
| `postgres_data` | Superset metadata, users, dashboards, charts, and connections |
| `redis_data` | Redis append-only data |
| `superset_home` | Superset home directory and bootstrap marker |

Back up `postgres_data` for production.

Keep these values stable after the first deployment:

- `SUPERSET_SECRET_KEY`
- `POSTGRES_PASSWORD`

Changing `SUPERSET_SECRET_KEY` can break encrypted metadata. Changing `POSTGRES_PASSWORD` does not update an existing PostgreSQL volume.

## Admin Commands

Reset the admin password from the `superset` container:

```bash
superset fab reset-password --username admin --password 'new-password'
```

Or use the helper script:

```bash
ADMIN_USERNAME=admin ADMIN_PASSWORD='new-password' /app/docker/reset-admin-password.sh
```

List users:

```bash
superset fab list-users
```

or:

```bash
/app/docker/list-users.sh
```

## Local Validation

Validate the Compose file:

```bash
docker compose --env-file .env.example config --quiet
```

Expected output is no output and exit code `0`.

Build locally if Docker is available:

```bash
docker compose --env-file .env.example build
```

## Example Deployment Shape

```text
Internet -> Coolify proxy -> superset:8088
                          -> db:5432 internal only
                          -> redis:6379 internal only
```

Only the `superset` service should receive a public domain.

## Troubleshooting

If Coolify shows an old service list after changes, click **Reload Compose File** and redeploy with **Force rebuild**.

If PostgreSQL authentication fails after changing `POSTGRES_PASSWORD`, the existing `postgres_data` volume was probably initialized with the old password. For a fresh setup, delete the `postgres_data` volume and redeploy.

If the domain returns a proxy `404`, confirm the domain is assigned to the `superset` service as `https://your-domain.example:8088` and not to the worker services.

## Contributing And Support

Issues and pull requests are welcome. Use the issue templates for deployment bugs, feature requests, or Coolify setup help.

Before opening a pull request, run:

```bash
docker compose --env-file .env.example config --quiet
```

See [CONTRIBUTING.md](CONTRIBUTING.md), [SUPPORT.md](SUPPORT.md), and [SECURITY.md](SECURITY.md).

## Security

- Keep `db` and `redis` internal.
- Do not expose host ports for PostgreSQL or Redis.
- Set a long random `SUPERSET_SECRET_KEY` for production.
- Change the default admin password before sharing access.
- Back up `postgres_data` before upgrades.

## License

This project is released under the [MIT License](LICENSE).
