#!/usr/bin/env bash

# Safe helper to allow both "source" and normal execution
_is_sourced() {
  # $0 is "bash" or "zsh" when sourced in interactive shells
  # BASH_SOURCE[0] != $0 is a common check
  [[ "${BASH_SOURCE[0]}" != "$0" ]]
}

# Path to .env (adjust if needed)
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

# Extract needed variables from .env
export INFISICAL_API_URL=$(grep -E '^INFISICAL_API_URL=' "$ENV_FILE" | cut -d '=' -f2-)
export INFISICAL_CLIENT_ID=$(grep -E '^INFISICAL_CLIENT_ID=' "$ENV_FILE" | cut -d '=' -f2-)
export INFISICAL_CLIENT_SECRET=$(grep -E '^INFISICAL_CLIENT_SECRET=' "$ENV_FILE" | cut -d '=' -f2-)

# Fallback for API URL (HTTP via nginx) if not set in .env
if [[ -z "$INFISICAL_API_URL" ]]; then
  INFISICAL_API_URL="http://10.95.35.9:8650/api"
  export INFISICAL_API_URL
fi

echo "[Infisical] Using API URL: $INFISICAL_API_URL"
echo "[Infisical] Logging in with universal auth..."

INFISICAL_TOKEN="$(
  infisical login \
    --method=universal-auth \
    --client-id="$INFISICAL_CLIENT_ID" \
    --client-secret="$INFISICAL_CLIENT_SECRET" \
    --domain="$INFISICAL_API_URL" \
    --silent \
    --plain
)"

if [[ -z "$INFISICAL_TOKEN" ]]; then
  echo "[Infisical] ERROR: Failed to obtain token."
  if _is_sourced; then
    return 1
  else
    exit 1
  fi
fi

export INFISICAL_TOKEN
echo "[Infisical] Got token: ${INFISICAL_TOKEN:0:16}…"
echo "[Infisical] Infisical CLI is now authenticated in this shell."
