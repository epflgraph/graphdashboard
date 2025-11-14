#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="/home/dockerhost"
ENV_FILE="${ROOT_DIR}/graphdashboard/.env"   # adjust if needed

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[Infisical] ERROR: .env not found at $ENV_FILE"
  exit 1
fi

PROJECT_ID=$(grep -E '^INFISICAL_PROJECT_ID_SECRETS=' "$ENV_FILE" | cut -d '=' -f2-)
if [[ -z "$PROJECT_ID" ]]; then
  echo "[Infisical] ERROR: INFISICAL_PROJECT_ID_SECRETS not set in $ENV_FILE"
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <env>"
  echo "Example: $0 dev"
  exit 1
fi

ENV="$1"
BACKUP_DIR="${ROOT_DIR}/.backups/infisical"
mkdir -p "$BACKUP_DIR"
OUT_FILE="${BACKUP_DIR}/secrets-${ENV}.env"

if [[ -z "${INFISICAL_TOKEN:-}" ]]; then
  echo "[Infisical] WARNING: INFISICAL_TOKEN is not set. Did you run login.sh?"
fi

echo "[Infisical] Backing up project=$PROJECT_ID env=$ENV → $OUT_FILE"

infisical secrets \
  --projectId="$PROJECT_ID" \
  --env="$ENV" \
  --recursive

# Call infisical and parse the table
infisical secrets \
  --projectId="$PROJECT_ID" \
  --env="$ENV" \
  --recursive \
  | awk '
    function trim(s) {
      gsub(/^[ \t\r\n]+/, "", s)
      gsub(/[ \t\r\n]+$/, "", s)
      return s
    }
    # Skip table borders and header separators
    /^┌/ || /^├/ || /^└/ { next }
    /^│ SECRET NAME/ { next }

    # Lines with data look like:
    # │ NAME │ VALUE │ TYPE │
    /^│/ {
      # remove leading/trailing borders
      line=$0
      sub(/^│[ ]*/, "", line)
      sub(/[ ]*│[ ]*$/, "", line)

      # split on │
      n = split(line, parts, /[|│]/)
      if (n >= 2) {
        name = trim(parts[1])
        value = trim(parts[2])
        if (name != "" && value != "") {
          # Escape any embedded double-quotes if needed later;
          # for dotenv, plain KEY=VALUE is usually fine
          printf("%s=%s\n", name, value)
        }
      }
    }
  ' > "$OUT_FILE"

echo "[Infisical] Backup complete. Wrote $(wc -l < "$OUT_FILE") entries to $OUT_FILE"
