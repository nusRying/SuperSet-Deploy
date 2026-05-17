#!/usr/bin/env bash
set -euo pipefail

: "${SUPERSET_SECRET_KEY:?SUPERSET_SECRET_KEY is required}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}"
: "${ADMIN_PASSWORD:?ADMIN_PASSWORD is required}"

rm -f /tmp/superset-init-complete

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

echo "Superset initialization complete."
touch /tmp/superset-init-complete

if [[ "${SUPERSET_INIT_STAY_ALIVE:-true}" == "true" ]]; then
  tail -f /dev/null
fi
