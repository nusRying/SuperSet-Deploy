#!/usr/bin/env bash
set -euo pipefail

: "${ADMIN_USERNAME:=admin}"
: "${ADMIN_PASSWORD:?ADMIN_PASSWORD is required}"

echo "Resetting Superset password for user '${ADMIN_USERNAME}'..."
superset fab reset-password --username "${ADMIN_USERNAME}" --password "${ADMIN_PASSWORD}"
echo "Password reset for user '${ADMIN_USERNAME}'."
