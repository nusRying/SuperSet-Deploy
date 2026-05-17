#!/usr/bin/env bash
set -euo pipefail

/app/docker/bootstrap-superset.sh
touch /tmp/superset-init-complete

if [[ "${SUPERSET_INIT_STAY_ALIVE:-true}" == "true" ]]; then
  tail -f /dev/null
fi
