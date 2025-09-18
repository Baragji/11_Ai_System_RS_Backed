#!/usr/bin/env bash
set -euo pipefail

: "${PGHOST:?environment variable required}"
: "${PGUSER:?environment variable required}"
: "${PGDATABASE:?environment variable required}"
: "${PGPASSWORD:?environment variable required}"
: "${BACKUP_FILE:?environment variable required}"

pg_restore --clean --if-exists --no-owner --no-privileges --verbose \
  --dbname="$PGDATABASE" "$BACKUP_FILE"
