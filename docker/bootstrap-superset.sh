#!/usr/bin/env bash
set -euo pipefail

: "${SUPERSET_SECRET_KEY:?SUPERSET_SECRET_KEY is required}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}"
: "${ADMIN_PASSWORD:?ADMIN_PASSWORD is required}"

echo "Waiting for Superset metadata database..."
python - <<'PY'
import os
import sys
import time

import psycopg2


deadline = time.time() + int(os.getenv("SUPERSET_DB_WAIT_TIMEOUT", "180"))
last_error = None

while time.time() < deadline:
    try:
        connection = psycopg2.connect(
            dbname=os.getenv("POSTGRES_DB", "superset"),
            user=os.getenv("POSTGRES_USER", "superset"),
            password=os.environ["POSTGRES_PASSWORD"],
            host=os.getenv("POSTGRES_HOST", "db"),
            port=int(os.getenv("POSTGRES_PORT", "5432")),
        )
        connection.close()
        sys.exit(0)
    except Exception as exc:
        last_error = exc
        time.sleep(2)

raise SystemExit(f"Could not connect to metadata database: {last_error}")
PY

echo "Running Superset database migrations..."
superset db upgrade

echo "Creating initial admin user if needed..."
superset fab create-admin \
  --username "${ADMIN_USERNAME:-admin}" \
  --firstname "${ADMIN_FIRST_NAME:-Superset}" \
  --lastname "${ADMIN_LAST_NAME:-Admin}" \
  --email "${ADMIN_EMAIL:-admin@example.com}" \
  --password "${ADMIN_PASSWORD}" || echo "Admin user already exists, continuing."

echo "Synchronizing Superset roles and permissions..."
superset init

if [[ "${SUPERSET_LOAD_EXAMPLES:-no}" == "yes" || "${SUPERSET_LOAD_EXAMPLES:-no}" == "true" ]]; then
  echo "Loading Superset example dashboards and datasets..."
  superset load_examples
fi

touch /app/superset_home/.bootstrap-complete
echo "Superset bootstrap complete."
