#!/usr/bin/env bash
# ============================================================================
# Application integration test - exercises the API through the load balancer.
# Usage:
#   bash tests/application/integration.sh <url>
#   bash tests/application/integration.sh https://app.example.com
# ============================================================================
set -uo pipefail

URL="${1:-http://localhost}"
PASS=0
FAIL=0

check() {
  if [ "$1" = "0" ]; then
    echo "  [PASS] $2"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $2"
    FAIL=$((FAIL + 1))
  fi
}

EMAIL="test-$(date +%s)@example.com"

echo "==> 1. Health endpoint"
CODE="$(curl -s -o /tmp/h.json -w '%{http_code}' "$URL/health")"
DB="$(grep -o '"db":"[a-z]*"' /tmp/h.json 2>/dev/null)"
[ "$CODE" = "200" ] && printf '%s' "$DB" | grep -q connected
check $? "GET /health -> 200, db connected ($DB)"

echo "==> 2. Register a user"
REG="$(curl -s -X POST "$URL/api/auth/register" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"password123\"}")"
TOKEN="$(printf '%s' "$REG" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)"
[ -n "$TOKEN" ]; check $? "register returns a token"

echo "==> 3. Login with the same credentials"
LOGIN="$(curl -s -X POST "$URL/api/auth/login" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"password123\"}")"
TOKEN2="$(printf '%s' "$LOGIN" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)"
[ -n "$TOKEN2" ]; check $? "login returns a token"

echo "==> 4. Wrong password is rejected (401)"
LOGIN_BAD="$(curl -s -o /dev/null -w '%{http_code}' -X POST "$URL/api/auth/login" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"wrong-password\"}")"
[ "$LOGIN_BAD" = "401" ]; check $? "login with wrong password -> 401 (got: $LOGIN_BAD)"

echo "==> 5. Create an item"
CREATE="$(curl -s -X POST "$URL/api/items" \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"title":"integration item","description":"from test"}')"
ITEM_ID="$(printf '%s' "$CREATE" | grep -o '"id":[0-9]*' | head -n1 | cut -d':' -f2)"
[ -n "$ITEM_ID" ]; check $? "create item returns an id (got: ${ITEM_ID:-none})"

echo "==> 6. List items contains the new item"
LIST="$(curl -s "$URL/api/items" -H "Authorization: Bearer $TOKEN")"
printf '%s' "$LIST" | grep -q "integration item"; check $? "list items contains the created item"

echo "==> 7. Unauthenticated request is rejected (401)"
UNAUTH="$(curl -s -o /dev/null -w '%{http_code}' "$URL/api/items")"
[ "$UNAUTH" = "401" ]; check $? "no token -> 401 (got: $UNAUTH)"

echo "==> 8. Delete the item"
DEL="$(curl -s -o /dev/null -w '%{http_code}' -X DELETE "$URL/api/items/$ITEM_ID" \
  -H "Authorization: Bearer $TOKEN")"
[ "$DEL" = "200" ]; check $? "delete item -> 200 (got: $DEL)"

echo ""
echo "==> RESULT: $PASS passed, $FAIL failed"
[ "$FAIL" = "0" ]
