#!/usr/bin/env sh
set -eu

export PGPASSWORD="${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}"

psql \
  -h 127.0.0.1 \
  -U "${POSTGRES_USER:-superset}" \
  -d "${POSTGRES_DB:-superset}" \
  -c "select 1" >/dev/null
