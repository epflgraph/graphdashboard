#!/bin/sh

echo "Enter Dashy username:"
read USERNAME

echo "Enter password (input hidden):"
stty -echo
read PASSWORD
stty echo
echo

# Generate SHA-256 hash (uppercase, as Dashy expects)
HASH=$(printf "%s" "$PASSWORD" | shasum -a 256 | awk '{print toupper($1)}')

echo
echo "Use this block in your Dashy config.yml:"
echo "----------------------------------------"
cat <<EOF
appConfig:
  auth:
    enableGuestAccess: false
    users:
      - user: $USERNAME
        hash: $HASH
        type: normal
EOF
echo "----------------------------------------"

echo "✅ Done."
