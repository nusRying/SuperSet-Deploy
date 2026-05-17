#!/usr/bin/env sh
set -eu

password="${POSTGRES_PASSWORD:-}"

if [ -z "$password" ] && [ -n "${POSTGRES_PASSWORD_FILE:-}" ]; then
  password="$(cat "$POSTGRES_PASSWORD_FILE")"
fi

export PGPASSWORD="$password"

psql \
  -h 127.0.0.1 \
  -U "${POSTGRES_USER:-superset}" \
  -d "${POSTGRES_DB:-superset}" \
  -c "select 1" >/dev/null
