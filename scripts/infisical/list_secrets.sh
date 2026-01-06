#!/usr/bin/env bash
set -euo pipefail

# Check environment argument
if [[ $# -ne 1 ]]; then
  echo "Usage: ./scripts/infisical/list_secrets.sh <dev|test|prod>"
  exit 1
fi

# Load infisical .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../../.infisical.env"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "[Infisical] ERROR: .env not found at $ENV_FILE"
  if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    return 1
  else
    exit 1
  fi
fi

# Extract needed variables from .env
export INFISICAL_SECRETS_PROJECTID=$(grep -E '^INFISICAL_SECRETS_PROJECTID=' "$ENV_FILE" | cut -d '=' -f2-)

# Print environment
echo "# Environment: $1"

# Just list secrets – NO login here
infisical secrets \
  --projectId="$INFISICAL_SECRETS_PROJECTID" \
  --env="$1" \
  --recursive \
  --output dotenv
echo
