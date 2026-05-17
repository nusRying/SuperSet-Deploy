#!/usr/bin/env bash
set -euo pipefail

exec celery \
  --app=superset.tasks.celery_app:app \
  beat \
  --loglevel="${CELERY_LOG_LEVEL:-INFO}" \
  --pidfile=/tmp/celerybeat.pid \
  --schedule=/app/superset_home/celerybeat-schedule
