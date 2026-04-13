#!/usr/bin/env bash
# setup.sh — Seeds E2E test accounts via the real API.
#
# Run from the repo root: bash mobile/e2e/seed/setup.sh
#
# Creates two accounts that are required by the E2E test suite:
#   alice@test.com / password123 — host (will own listings)
#   bob@test.com   / password123 — renter
#
# Idempotent: re-running only fails if the accounts already exist (409),
# which is silently ignored.

set -euo pipefail

API_URL="${API_URL:-http://localhost:8080}"

register_user() {
  local name="$1"
  local email="$2"
  local password="$3"

  status=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "${API_URL}/api/v1/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"${name}\",\"email\":\"${email}\",\"password\":\"${password}\"}")

  if [ "$status" = "201" ]; then
    echo "  Created: ${email}"
  elif [ "$status" = "409" ]; then
    echo "  Already exists (ok): ${email}"
  else
    echo "  ERROR registering ${email}: HTTP ${status}" >&2
    exit 1
  fi
}

echo "Seeding E2E test accounts against ${API_URL}..."
register_user "Alice Host"  "alice@test.com" "password123"
register_user "Bob Renter"  "bob@test.com"   "password123"
echo "Done."
