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

4. Set these required environment variables in Coolify, not in GitHub:

   ```env
   SUPERSET_SECRET_KEY=<output of: openssl rand -base64 42>
   POSTGRES_PASSWORD=<strong database password>
   ADMIN_PASSWORD=<strong initial admin password>
   ```

5. Optionally set:

   ```env
   ADMIN_USERNAME=admin
   ADMIN_EMAIL=you@example.com
   SUPERSET_VERSION=latest
   POSTGRES_VERSION=16-alpine
   SUPERSET_PIP_PACKAGES=psycopg2-binary redis gevent openpyxl
   POSTGRES_SYNC_PASSWORD=true
   SUPERSET_LOAD_EXAMPLES=no
   ```

   Add any data warehouse drivers you need to `SUPERSET_PIP_PACKAGES`, for example `pymssql`, `trino`, `sqlalchemy-bigquery`, or `clickhouse-connect`.

6. Assign your domain to the `superset` service, using container port `8088`.

   Example:

   ```text
   https://superset.example.com:8088
   ```

   The `:8088` tells Coolify which container port to proxy to. Visitors still use normal HTTPS at `https://superset.example.com`.

7. Deploy.
8. Log in with `ADMIN_USERNAME` and `ADMIN_PASSWORD`.

## GitHub Safety

- Commit `.env.example`, but do not commit `.env`.
- Store real passwords and `SUPERSET_SECRET_KEY` only in Coolify environment variables.
- Keep the repository private if you do not want your deployment topology public.
- Keep `.gitattributes` committed. It prevents Windows CRLF line endings from breaking shell scripts inside Linux containers.

## Important Production Notes

- Keep `SUPERSET_SECRET_KEY` stable after the first deploy. Changing it without following Superset's key rotation process can break encrypted metadata such as database credentials.
- Keep `POSTGRES_PASSWORD` stable after the first deploy when possible. This deployment includes a small Postgres wrapper that syncs the existing `superset` role password to the current Coolify `POSTGRES_PASSWORD` on container startup, which recovers from common first-deploy password mismatches.
- The official Superset production guidance expects you to extend the `lean` image and install your own database drivers. This Dockerfile installs the PostgreSQL metadata driver plus Redis/Gunicorn helpers by default.
- Back up the `postgres_data` Docker volume. Superset dashboards, charts, users, and database connection metadata live in PostgreSQL.
- Do not expose the `db` or `redis` services publicly. This compose file intentionally uses `expose` only for Superset and no host port mappings.
- If you use HTTP instead of HTTPS for testing, set `SESSION_COOKIE_SECURE=false` and `PREFERRED_URL_SCHEME=http`.

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
