#!/usr/bin/env sh
set -eu

if [ "${1:-}" != "postgres" ] && [ "${1#-}" = "$1" ]; then
  exec /usr/local/bin/docker-entrypoint.sh "$@"
fi

if [ "${1#-}" != "$1" ]; then
  set -- postgres "$@"
fi

load_file_env() {
  var="$1"
  file_var="${var}_FILE"
  file_path="$(eval "printf '%s' \"\${$file_var:-}\"")"
  value="$(eval "printf '%s' \"\${$var:-}\"")"

  if [ -z "$value" ] && [ -n "$file_path" ]; then
    echo "Waiting for $file_path..."
    while [ ! -f "$file_path" ]; do
      sleep 1
    done
    export "$var=$(cat "$file_path")"
    unset "$file_var"
  fi
}

sync_postgres_password() {
  db_name="${POSTGRES_DB:-$POSTGRES_USER}"
  db_port="${POSTGRES_PORT:-5432}"
  attempt=1

  echo "Waiting for PostgreSQL local socket..."
  until pg_isready -h /var/run/postgresql -p "$db_port" >/dev/null 2>&1; do
    if ! kill -0 "$postgres_pid" >/dev/null 2>&1; then
      wait "$postgres_pid"
      exit $?
    fi
    sleep 1
  done

  echo "Synchronizing PostgreSQL password for role '$POSTGRES_USER'..."
  while [ "$attempt" -le 30 ]; do
    if psql -v ON_ERROR_STOP=1 \
      -h /var/run/postgresql \
      -p "$db_port" \
      -U "$POSTGRES_USER" \
      -d "$db_name" \
      -v db_user="$POSTGRES_USER" \
      -v db_password="$POSTGRES_PASSWORD" <<'SQL'
ALTER ROLE :"db_user" WITH PASSWORD :'db_password';
SQL
    then
      echo "PostgreSQL password synchronized."
      return 0
    fi

    if psql -v ON_ERROR_STOP=1 \
      -h /var/run/postgresql \
      -p "$db_port" \
      -U "$POSTGRES_USER" \
      -d postgres \
      -v db_user="$POSTGRES_USER" \
      -v db_password="$POSTGRES_PASSWORD" <<'SQL'
ALTER ROLE :"db_user" WITH PASSWORD :'db_password';
SQL
    then
      echo "PostgreSQL password synchronized."
      return 0
    fi

    attempt=$((attempt + 1))
    sleep 2
  done

  echo "Could not synchronize PostgreSQL password after 30 attempts." >&2
  return 1
}

stop_postgres() {
  kill -TERM "$postgres_pid" >/dev/null 2>&1 || true
  wait "$postgres_pid" || true
  exit 0
}

trap stop_postgres INT TERM

load_file_env POSTGRES_PASSWORD

/usr/local/bin/docker-entrypoint.sh "$@" &
postgres_pid="$!"

if [ "${POSTGRES_SYNC_PASSWORD:-true}" = "true" ]; then
  : "${POSTGRES_USER:?POSTGRES_USER is required}"
  : "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}"
  sync_postgres_password
fi

wait "$postgres_pid"
