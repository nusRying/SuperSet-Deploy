# Apache Superset on Coolify

This folder contains a Coolify-friendly Docker Compose deployment for Apache Superset.

## What It Runs

- `superset`: the web app on container port `8088`; it also runs idempotent migrations, admin user creation, and role sync before starting
- `superset-worker`: Celery worker for background tasks
- `superset-worker-beat`: Celery scheduler
- `db`: PostgreSQL metadata database
- `redis`: cache and Celery broker/result backend

## GitHub To Coolify Deployment Steps

1. Push this folder to a GitHub repository.
2. In Coolify, create a new resource from the GitHub repository.
3. Select the **Docker Compose** build pack and use:

   ```text
   docker-compose.yml
   ```

4. Optionally set:

   ```env
   ADMIN_USERNAME=admin
   ADMIN_EMAIL=you@example.com
   POSTGRES_VERSION=16-alpine
   SUPERSET_PIP_PACKAGES=psycopg2-binary redis gevent openpyxl
   SUPERSET_SECRET_KEY=be2206fbc1e26b61c76281d6486170eb4939610393ee38253cc626ffe1c7fa660798129ef4703c9447f73d153b4ea343
   POSTGRES_PASSWORD=c18f29fab54bca03c6336522cb632970c86dcf531aef7ce19862e26837f777d111e48db4dcdede0015e5f73c5786edd8
   ADMIN_PASSWORD=Kutraa1213
   SUPERSET_RESET_ADMIN_PASSWORD=true
   SUPERSET_LOAD_EXAMPLES=no
   ```

   `SUPERSET_SECRET_KEY`, `POSTGRES_PASSWORD`, and `ADMIN_PASSWORD` already have generated defaults in `docker-compose.yml`, so you do not need to set them in Coolify unless you want to override them.
   Add any data warehouse drivers you need to `SUPERSET_PIP_PACKAGES`, for example `pymssql`, `trino`, `sqlalchemy-bigquery`, or `clickhouse-connect`.
   Leave `SUPERSET_SQLALCHEMY_DATABASE_URI` unset unless you intentionally want to use an external metadata database.

5. Assign your domain to the `superset` service, using container port `8088`.

   Example:

   ```text
   https://superset.example.com:8088
   ```

   The `:8088` tells Coolify which container port to proxy to. Visitors still use normal HTTPS at `https://superset.example.com`.

6. Deploy.
7. Log in with `ADMIN_USERNAME` and `ADMIN_PASSWORD`.

## GitHub Safety

- Commit `.env.example`, but do not commit `.env`.
- Generated default passwords and `SUPERSET_SECRET_KEY` are committed in `docker-compose.yml` and `.env.example` for private-repo convenience.
- Keep the repository private if you do not want your deployment topology public.
- Keep `.gitattributes` committed. It prevents Windows CRLF line endings from breaking shell scripts inside Linux containers.

## Important Production Notes

- Keep `SUPERSET_SECRET_KEY` stable after the first deploy. Changing it without following Superset's key rotation process can break encrypted metadata such as database credentials.
- Keep `POSTGRES_PASSWORD` stable after the first deploy. The official Postgres image only applies it when the database volume is first initialized.
- Superset builds its metadata DB connection from `POSTGRES_*` variables. Do not set `SQLALCHEMY_DATABASE_URI` in Coolify for this deployment; use `SUPERSET_SQLALCHEMY_DATABASE_URI` only if you intentionally manage an external metadata database.
- The official Superset production guidance expects you to extend the `lean` image and install your own database drivers. This Dockerfile installs the PostgreSQL metadata driver plus Redis/Gunicorn helpers by default.
- Back up the `postgres_data` Docker volume. Superset dashboards, charts, users, and database connection metadata live in PostgreSQL.
- Do not expose the `db` or `redis` services publicly. This compose file intentionally uses `expose` only for Superset and no host port mappings.
- If you use HTTP instead of HTTPS for testing, set `SESSION_COOKIE_SECURE=false` and `PREFERRED_URL_SCHEME=http`.
- If Coolify still shows a `secrets` service, it is deploying an older compose file. Push the latest commit, click **Reload Compose File**, then redeploy with **Force rebuild**.

## Fix Postgres Password Mismatch

If Superset logs show:

```text
password authentication failed for user "superset"
```

then the existing `postgres_data` volume was initialized with a different password than the current `POSTGRES_PASSWORD` in Coolify. With the current compose file, redeploying should automatically sync the database password.

For a fresh install with no dashboards/data yet, you can also delete the app's `postgres_data` persistent volume in Coolify and redeploy. This recreates Postgres using the current `POSTGRES_PASSWORD`.

If you need to keep existing Superset data, open a terminal into the `db` container and change the database user's password to match the current Coolify `POSTGRES_PASSWORD`:

```bash
psql -U superset -d superset -c "ALTER USER superset WITH PASSWORD 'your-current-postgres-password';"
```

## Reset Admin Password

If the initial login does not work, open a terminal into the `superset` container in Coolify and list users:

```bash
/app/docker/list-users.sh
```

Then reset the password:

```bash
ADMIN_USERNAME=admin ADMIN_PASSWORD=Kutraa1213 /app/docker/reset-admin-password.sh
```

Then log in with:

```text
Username: admin
Password: Kutraa1213
```

## Local Smoke Test

For local testing only:

```bash
cp .env.example .env
docker compose up --build
```

Then open:

```text
http://localhost:8088
```

For local testing, either add a temporary `ports` mapping to the `superset` service or access it through your Docker network tooling. Do not commit host port mappings unless you intend to bypass Coolify's proxy.
