#!/usr/bin/env bash
set -euo pipefail

load_secret() {
  local env_name="$1"
  local file_name="${env_name}_FILE"
  local value="${!env_name:-}"
  local file_path="${!file_name:-}"

  if [[ -z "${value}" && -n "${file_path}" ]]; then
    until [[ -f "${file_path}" ]]; do
      echo "Waiting for ${file_path}..."
      sleep 2
    done
    export "${env_name}=$(<"${file_path}")"
  fi

  : "${!env_name:?${env_name} is required}"
}

load_secret SUPERSET_SECRET_KEY
load_secret POSTGRES_PASSWORD
load_secret ADMIN_PASSWORD

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
