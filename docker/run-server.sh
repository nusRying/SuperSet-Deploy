#!/usr/bin/env bash
set -euo pipefail

/app/docker/bootstrap-superset.sh

exec gunicorn \
  --bind "0.0.0.0:8088" \
  --workers "${SUPERSET_WEBSERVER_WORKERS:-2}" \
  --worker-class "${SUPERSET_WEBSERVER_WORKER_CLASS:-gevent}" \
  --threads "${SUPERSET_WEBSERVER_THREADS:-20}" \
  --timeout "${SUPERSET_WEBSERVER_TIMEOUT:-120}" \
  --limit-request-line 0 \
  --limit-request-field_size 0 \
  "superset.app:create_app()"
