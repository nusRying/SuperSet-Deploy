# Apache Superset on Coolify

This repository contains a working Docker Compose deployment for Apache Superset on Coolify.

It uses the official Superset image as a base, installs the drivers needed for this stack, and runs Superset behind Coolify's reverse proxy on container port `8088`.

## Services

- `superset`: web app on port `8088`; runs migrations, creates the admin user, resets the admin password, and starts Gunicorn
- `superset-worker`: Celery worker for background jobs
- `superset-worker-beat`: Celery scheduler
- `db`: PostgreSQL metadata database
- `redis`: cache, Celery broker, and Celery result backend

## Default Login

```text
URL: https://your-domain.com
Username: admin
Password: Kutraa1213
```

The default password is set in `docker-compose.yml` through `ADMIN_PASSWORD`. On every deploy, the startup script resets the `admin` user's password when `SUPERSET_RESET_ADMIN_PASSWORD=true`.

## Deploy On Coolify

1. Create a new Coolify resource from this GitHub repository.
2. Select the **Docker Compose** build pack.
3. Use this compose file path:

   ```text
   docker-compose.yml
   ```

4. In the **Domains for superset** field, set your domain with the internal container port:

   ```text
   https://your-domain.com:8088
   ```

   Visitors should open:

   ```text
   https://your-domain.com
   ```

5. Leave domains blank for:

   ```text
   superset-worker
   superset-worker-beat
   ```

6. Deploy. If Coolify was already using an older compose file, click **Reload Compose File** and redeploy with **Force rebuild**.

## Configuration

The compose file includes working defaults, so no Coolify environment variables are required for a basic deploy.

Useful optional overrides:

```env
ADMIN_USERNAME=admin
ADMIN_PASSWORD=Kutraa1213
ADMIN_EMAIL=admin@example.com
POSTGRES_VERSION=16-alpine
POSTGRES_DB=superset
POSTGRES_USER=superset
POSTGRES_PASSWORD=c18f29fab54bca03c6336522cb632970c86dcf531aef7ce19862e26837f777d111e48db4dcdede0015e5f73c5786edd8
SUPERSET_SECRET_KEY=be2206fbc1e26b61c76281d6486170eb4939610393ee38253cc626ffe1c7fa660798129ef4703c9447f73d153b4ea343
SUPERSET_RESET_ADMIN_PASSWORD=true
SUPERSET_LOAD_EXAMPLES=no
SUPERSET_PIP_PACKAGES=psycopg2-binary redis gevent openpyxl
```

Add database drivers to `SUPERSET_PIP_PACKAGES` when needed, for example:

```env
SUPERSET_PIP_PACKAGES=psycopg2-binary redis gevent openpyxl trino sqlalchemy-bigquery clickhouse-connect
```

Do not set `SQLALCHEMY_DATABASE_URI` in Coolify for this deployment. Superset builds its metadata database URL from the `POSTGRES_*` variables. Use `SUPERSET_SQLALCHEMY_DATABASE_URI` only if you intentionally move the metadata database outside this Compose stack.

## Persistent Data

Coolify/Docker creates these volumes:

- `postgres_data`: Superset metadata, users, dashboards, charts, and database connection records
- `redis_data`: Redis persistence
- `superset_home`: Superset home directory and bootstrap marker

Back up `postgres_data`. That is the important application data.

Keep these values stable after the first production deploy:

- `SUPERSET_SECRET_KEY`
- `POSTGRES_PASSWORD`

Changing `SUPERSET_SECRET_KEY` can break encrypted metadata. Changing `POSTGRES_PASSWORD` does not update an already initialized Postgres volume.

## Reset Admin Password

Open a terminal into the `superset` container in Coolify and run:

```bash
superset fab reset-password --username admin --password Kutraa1213
```

Or use the helper script:

```bash
ADMIN_USERNAME=admin ADMIN_PASSWORD=Kutraa1213 /app/docker/reset-admin-password.sh
```

To list users:

```bash
superset fab list-users
```

or:

```bash
/app/docker/list-users.sh
```

## Postgres Password Mismatch

If logs show:

```text
password authentication failed for user "superset"
```

then the existing `postgres_data` volume was initialized with a different `POSTGRES_PASSWORD`.

For a fresh setup, delete the app's `postgres_data` persistent volume in Coolify and redeploy.

If you need to keep existing data, open a terminal into the `db` container and change the DB user password to match the current `POSTGRES_PASSWORD`:

```bash
psql -U superset -d superset -c "ALTER USER superset WITH PASSWORD 'your-current-postgres-password';"
```

## Notes

- The `db` and `redis` services are internal only and should not get domains.
- The Superset service uses `expose: 8088`, not public host port mappings.
- `.gitattributes` keeps shell scripts with Linux line endings when editing from Windows.
- The warnings about CSP and Flask-Limiter in the Superset logs are not startup blockers.
