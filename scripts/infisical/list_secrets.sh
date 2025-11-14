#!/usr/bin/env bash

# Detect if script is sourced
_is_sourced() {
  [[ "${BASH_SOURCE[0]}" != "$0" ]]
}

# Path to .env (adjust if your layout is different)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../../.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[Infisical] ERROR: .env not found at $ENV_FILE"
  if _is_sourced; then
    return 1
  else
    exit 1
  fi
fi

# Load project + env from .env
INFISICAL_PROJECT_ID_SECRETS=$(grep -E '^INFISICAL_PROJECT_ID_SECRETS=' "$ENV_FILE" | cut -d '=' -f2-)
INFISICAL_ENV=$(grep -E '^INFISICAL_ENV=' "$ENV_FILE" | cut -d '=' -f2-)

# Defaults
if [[ -z "$INFISICAL_ENV" ]]; then
  INFISICAL_ENV="dev"
fi

# Require an existing token (set by login.sh)
if [[ -z "$INFISICAL_TOKEN" ]]; then
  echo "[Infisical] ERROR: INFISICAL_TOKEN is not set."
  echo "          Run: source ./scripts/infisical/login.sh"
  if _is_sourced; then
    return 1
  else
    exit 1
  fi
fi

# Optional: show which project/env we’re hitting
echo "[Infisical] Listing secrets for:"
echo "  project: $INFISICAL_PROJECT_ID_SECRETS"
echo "  env:     $INFISICAL_ENV"
echo

# Just list secrets – NO login here
infisical secrets \
  --projectId="$INFISICAL_PROJECT_ID_SECRETS" \
  --env="$INFISICAL_ENV" \
  --recursive
