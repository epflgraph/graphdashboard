#!/usr/bin/env bash
set -euo pipefail

# Verify if user logged in
if [[ -z "${INFISICAL_TOKEN:-}" ]]; then
  echo "[Infisical] WARNING: INFISICAL_TOKEN is not set. Did you run login.sh?"
  exit 1
fi

# Get current date in YYYY-MM-DD format
DATE=$(date +%Y-%m-%d)

# Define paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="/home/dockerhost"
BACKUP_DIR="${ROOT_DIR}/.backups/infisical/${DATE}"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Run list_secrets.sh script for each environment
ENVIRONMENTS=("dev" "coresrv" "test" "prod")
for ENV in "${ENVIRONMENTS[@]}"; do
    OUT_FILE="${BACKUP_DIR}/secrets-${ENV}.env"
    echo "[Infisical] Backing up project env=$ENV → $OUT_FILE"
    ${SCRIPT_DIR}/list_secrets.sh "$ENV" > "$OUT_FILE"

    # Optional: Verify if the backup was created successfully
    if [[ -f "$OUT_FILE" ]]; then
        echo "[Infisical] Backup for env=$ENV completed successfully."
    else
        echo "[Infisical] ERROR: Backup for env=$ENV failed."
    fi
done

# Final message
echo "[Infisical] Backup complete."
