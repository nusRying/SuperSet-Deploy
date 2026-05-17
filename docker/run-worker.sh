#!/usr/bin/env bash
set -euo pipefail

exec celery \
  --app=superset.tasks.celery_app:app \
  worker \
  --loglevel="${CELERY_LOG_LEVEL:-INFO}" \
  -Ofair
