#!/usr/bin/env bash
set -euo pipefail

if [[ "${SUPERSET_WAIT_FOR_BOOTSTRAP:-true}" == "true" ]]; then
  echo "Waiting for Superset bootstrap to complete..."
  until [[ -f /app/superset_home/.bootstrap-complete ]]; do
    sleep 5
  done
fi

exec celery \
  --app=superset.tasks.celery_app:app \
  worker \
  --loglevel="${CELERY_LOG_LEVEL:-INFO}" \
  -Ofair
