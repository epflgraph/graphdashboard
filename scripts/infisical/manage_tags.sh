#!/usr/bin/env bash
set -euo pipefail

# -------------------------------
# Config / .env loading
# -------------------------------
ENV_FILE="${ENV_FILE:-.env}"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: .env file not found at $ENV_FILE" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

: "${INFISICAL_URL:?missing in .env}"
: "${INFISICAL_PROJECT_ID:?missing in .env}"
: "${INFISICAL_TOKEN:?missing in .env}"

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq is required but not installed." >&2
  exit 1
fi

# -------------------------------
# Colour handling
# -------------------------------
# Supported named colours → hex
get_color_hex() {
  local input="$1"

  # If already hex, normalise and return
  if [[ "$input" =~ ^#?[0-9a-fA-F]{6}$ ]]; then
    # ensure leading '#'
    if [[ "$input" =~ ^# ]]; then
      echo "$input"
    else
      echo "#$input"
    fi
    return 0
  fi

  # Normalize name (lowercase)
  local name
  name="$(echo "$input" | tr '[:upper:]' '[:lower:]')"

  case "$name" in
    red)        echo "#e74c3c" ;;
    orange)     echo "#e67e22" ;;
    yellow)     echo "#f1c40f" ;;
    green)      echo "#27ae60" ;;
    teal)       echo "#1abc9c" ;;
    cyan)       echo "#00bcd4" ;;
    blue)       echo "#3498db" ;;
    indigo)     echo "#3f51b5" ;;
    purple)     echo "#9b59b6" ;;
    pink)       echo "#e91e63" ;;
    grey|gray)  echo "#95a5a6" ;;
    black)      echo "#000000" ;;
    white)      echo "#ffffff" ;;
    *)
      echo "ERROR: Unsupported colour '$input'." >&2
      echo "Run: $0 colour    # to list supported colour names" >&2
      return 1
      ;;
  esac
}

show_supported_colors() {
  cat <<EOF
Supported colour names (mapped to hex):

  red      -> #e74c3c
  orange   -> #e67e22
  yellow   -> #f1c40f
  green    -> #27ae60
  teal     -> #1abc9c
  cyan     -> #00bcd4
  blue     -> #3498db
  indigo   -> #3f51b5
  purple   -> #9b59b6
  pink     -> #e91e63
  grey     -> #95a5a6
  gray     -> #95a5a6
  black    -> #000000
  white    -> #ffffff

You can also pass a raw hex code, e.g.:

  #ff0000   or   ff0000
EOF
}

# -------------------------------
# API helpers
# -------------------------------
api_get() {
  local path="$1"
  curl -sS \
    -H "Authorization: Bearer $INFISICAL_TOKEN" \
    "$INFISICAL_URL$path"
}

api_patch() {
  local path="$1"
  local data="$2"
  curl -sS -X PATCH \
    -H "Authorization: Bearer $INFISICAL_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$data" \
    "$INFISICAL_URL$path"
}

# -------------------------------
# Tag operations
# -------------------------------
list_tags() {
  api_get "/api/v1/projects/$INFISICAL_PROJECT_ID/tags" | jq .
}

get_tag_by_slug() {
  local slug="$1"
  api_get "/api/v1/projects/$INFISICAL_PROJECT_ID/tags/slug/$slug"
}

rename_tag() {
  local old_slug="$1"
  local new_slug="$2"

  local tag_json
  tag_json="$(get_tag_by_slug "$old_slug" 2>/dev/null || true)"

  local tag_id
  tag_id="$(echo "$tag_json" | jq -r '.tag.id // empty')"

  if [ -z "$tag_id" ]; then
    echo "ERROR: Tag with slug '$old_slug' not found." >&2
    exit 1
  fi

  # keep existing colour if present
  local existing_color
  existing_color="$(echo "$tag_json" | jq -r '.tag.color // ""')"

  if [ -n "$existing_color" ] && [ "$existing_color" != "null" ]; then
    payload=$(jq -n --arg slug "$new_slug" --arg color "$existing_color" \
      '{slug: $slug, color: $color}')
  else
    payload=$(jq -n --arg slug "$new_slug" '{slug: $slug}')
  fi

  api_patch "/api/v1/projects/$INFISICAL_PROJECT_ID/tags/$tag_id" "$payload" | jq .
}

change_tag_color() {
  local slug="$1"
  local color_input="$2"

  local new_color
  new_color="$(get_color_hex "$color_input")" || exit 1

  local tag_json
  tag_json="$(get_tag_by_slug "$slug" 2>/dev/null || true)"

  local tag_id
  tag_id="$(echo "$tag_json" | jq -r '.tag.id // empty')"

  if [ -z "$tag_id" ]; then
    echo "ERROR: Tag with slug '$slug' not found." >&2
    exit 1
  fi

  local existing_slug
  existing_slug="$(echo "$tag_json" | jq -r '.tag.slug')"

  payload=$(jq -n --arg slug "$existing_slug" --arg color "$new_color" \
    '{slug: $slug, color: $color}')

  api_patch "/api/v1/projects/$INFISICAL_PROJECT_ID/tags/$tag_id" "$payload" | jq .
}

usage() {
  cat <<EOF
Usage:
  $0 list
      List all tags.

  $0 rename <old-slug> <new-slug>
      Rename a tag (keeps existing colour).

  $0 colour
      List supported colour names.

  $0 colour <slug> <colour-name-or-hex>
      Change a tag's colour. Examples:
        $0 colour prod red
        $0 colour staging "#3498db"
        $0 colour featureX ff00aa
EOF
}

# -------------------------------
# Main
# -------------------------------
COMMAND="${1:-}"

case "$COMMAND" in
  list)
    list_tags
    ;;
  rename)
    if [ "$#" -ne 3 ]; then
      echo "ERROR: rename requires <old-slug> and <new-slug>" >&2
      usage
      exit 1
    fi
    rename_tag "$2" "$3"
    ;;
  colour|color)
    if [ "$#" -eq 1 ]; then
      show_supported_colors
      exit 0
    fi
    if [ "$#" -ne 3 ]; then
      echo "ERROR: colour requires either no args or: <slug> <colour-name-or-hex>" >&2
      usage
      exit 1
    fi
    change_tag_color "$2" "$3"
    ;;
  *)
    usage
    exit 1
    ;;
esac
