# Apache Superset on Coolify

Docker Compose setup for running Apache Superset on Coolify.

The stack includes Superset, PostgreSQL, Redis, a Celery worker, and a Celery beat scheduler. Superset is exposed through Coolify's proxy on container port `8088`.

## Services

- `superset`: Superset web app
- `superset-worker`: Celery worker
- `superset-worker-beat`: Celery scheduler
- `db`: PostgreSQL metadata database
- `redis`: cache and Celery backend

## Deploy

1. Create a new Coolify resource from this repository.
2. Select the **Docker Compose** build pack.
3. Use:

   ```text
   docker-compose.yml
   ```

4. Assign your domain to the `superset` service with container port `8088`:

   ```text
   https://your-domain.example:8088
   ```

   Users should visit:

   ```text
   https://your-domain.example
   ```

5. Leave domains blank for worker services.
6. Deploy.

## Configuration

The compose file includes defaults for a quick private deployment. Override these in Coolify for production:

```env
ADMIN_USERNAME=admin
ADMIN_PASSWORD=change-me
ADMIN_EMAIL=admin@example.com
POSTGRES_PASSWORD=change-me
SUPERSET_SECRET_KEY=change-me-to-a-long-random-secret
SUPERSET_LOAD_EXAMPLES=no
SUPERSET_RESET_ADMIN_PASSWORD=true
```

Add database drivers through:

```env
SUPERSET_PIP_PACKAGES=psycopg2-binary redis gevent openpyxl
```

For example, append drivers such as `trino`, `sqlalchemy-bigquery`, or `clickhouse-connect` if you need those database connections.

## Data

Persistent volumes:

- `postgres_data`: Superset metadata, users, dashboards, charts, and connections
- `redis_data`: Redis data
- `superset_home`: Superset runtime home directory

Back up `postgres_data` for production.

Keep `SUPERSET_SECRET_KEY` and `POSTGRES_PASSWORD` stable after the first deploy. Changing them later can break encrypted metadata or database access.

## Admin Password

To reset the admin password from the `superset` container:

```bash
superset fab reset-password --username admin --password 'new-password'
```

Or use the helper script:

```bash
ADMIN_USERNAME=admin ADMIN_PASSWORD='new-password' /app/docker/reset-admin-password.sh
```

To list users:

```bash
superset fab list-users
```

## Troubleshooting

If Coolify shows an old service list after changes, click **Reload Compose File** and redeploy with **Force rebuild**.

If PostgreSQL authentication fails after changing `POSTGRES_PASSWORD`, the existing `postgres_data` volume was probably initialized with the old password. For a fresh setup, delete the `postgres_data` volume and redeploy.

Do not assign public domains to `db`, `redis`, `superset-worker`, or `superset-worker-beat`.
