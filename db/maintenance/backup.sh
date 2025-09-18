#!/usr/bin/env bash
set -euo pipefail

: "${PGHOST:?environment variable required}"
: "${PGUSER:?environment variable required}"
: "${PGDATABASE:?environment variable required}"
: "${PGPASSWORD:?environment variable required}"

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/postgres}"
mkdir -p "$BACKUP_DIR"

pg_dump --format=custom --file="$BACKUP_DIR/${PGDATABASE}_${TIMESTAMP}.dump" \
  --no-owner --no-privileges --verbose
