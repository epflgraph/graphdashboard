#!/usr/bin/env bash
set -euo pipefail

# load .env safely (ignore commented lines)
ENV_FILE="${ENV_FILE:-.env}"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: .env file not found at $ENV_FILE"
  exit 1
fi

# Export variables in .env
set -a
source "$ENV_FILE"
set +a

# ensure required variables exist
: "${INFISICAL_URL:?missing in .env}"
: "${INFISICAL_PROJECT_ID:?missing in .env}"
: "${INFISICAL_TOKEN:?missing in .env}"

curl -sS \
  -H "Authorization: Bearer $INFISICAL_TOKEN" \
  "$INFISICAL_URL/api/v1/projects/$INFISICAL_PROJECT_ID/tags" \
  | jq .
