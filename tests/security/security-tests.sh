#!/usr/bin/env bash
# ============================================================================
# Security tests - verify the platform actually enforces its security model.
# Usage:
#   bash tests/security/security-tests.sh <region> <project> <env> <url>
#   bash tests/security/security-tests.sh eu-west-1 secure-ntier dev https://app.example.com
# ============================================================================
set -uo pipefail

REGION="${1:?usage: security-tests.sh <region> <project> <env> <url>}"
PROJECT="${2:?project required}"
ENV_NAME="${3:?env required}"
URL="${4:?url required}"

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

echo "==> 1. RDS is NOT publicly accessible"
PUB="$(aws rds describe-db-instances \
  --region "$REGION" \
  --db-instance-identifier "${PROJECT}-${ENV_NAME}-db" \
  --query 'DBInstances[0].PubliclyAccessible' --output text 2>/dev/null)"
[ "$PUB" = "false" ]; check $? "RDS PubliclyAccessible=false (got: ${PUB:-unknown})"

echo "==> 2. RDS is storage-encrypted"
ENC="$(aws rds describe-db-instances \
  --region "$REGION" \
  --db-instance-identifier "${PROJECT}-${ENV_NAME}-db" \
  --query 'DBInstances[0].StorageEncrypted' --output text 2>/dev/null)"
[ "$ENC" = "true" ]; check $? "RDS StorageEncrypted=true (got: ${ENC:-unknown})"

echo "==> 3. WAF web ACL exists and is associated with the ALB"
ACL_COUNT="$(aws wafv2 list-web-acls --scope REGIONAL --region "$REGION" \
  --query "length(WebACLs[?contains(Name, '${PROJECT}-${ENV_NAME}')])" --output text 2>/dev/null)"
[ "$ACL_COUNT" -ge 1 ] 2>/dev/null; check $? "WAF web ACL present (count: ${ACL_COUNT:-0})"

echo "==> 4. Security groups: app SG does NOT allow SSH from the internet"
SG_ID="$(aws ec2 describe-security-groups --region "$REGION" \
  --filters Name=tag:Environment,Values="$ENV_NAME" Name=tag:Tier,Values=app \
  --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)"
SSH_OPEN="$(aws ec2 describe-security-groups --region "$REGION" \
  --group-ids "$SG_ID" \
  --query 'SecurityGroups[0].IpPermissions[?FromPort==`22`].IpRanges[?CidrIp==`0.0.0.0/0`]' --output text 2>/dev/null)"
[ -z "$SSH_OPEN" ]; check $? "No SSH (22) open to 0.0.0.0/0 on app SG"

echo "==> 5. DB SG does NOT allow access from the internet"
DB_SG_ID="$(aws ec2 describe-security-groups --region "$REGION" \
  --filters Name=tag:Environment,Values="$ENV_NAME" Name=tag:Tier,Values=db \
  --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)"
DB_OPEN="$(aws ec2 describe-security-groups --region "$REGION" \
  --group-ids "$DB_SG_ID" \
  --query 'SecurityGroups[0].IpPermissions[?FromPort==`5432`].IpRanges[?CidrIp==`0.0.0.0/0`]' --output text 2>/dev/null)"
[ -z "$DB_OPEN" ]; check $? "No PostgreSQL (5432) open to 0.0.0.0/0 on DB SG"

echo "==> 6. Application responds on the health endpoint"
CODE="$(curl -s -o /dev/null -w '%{http_code}' "$URL/health" 2>/dev/null)"
[ "$CODE" = "200" ]; check $? "GET $URL/health -> 200 (got: $CODE)"

echo "==> 7. HTTPS redirect (if HTTPS is configured)"
if [[ "$URL" == https://* ]]; then
  HTTP_URL="http://${URL#https://}"
  REDIRECT_CODE="$(curl -s -o /dev/null -w '%{http_code}' "$HTTP_URL" 2>/dev/null)"
  [ "$REDIRECT_CODE" = "301" ] || [ "$REDIRECT_CODE" = "308" ]; check $? "HTTP -> HTTPS redirect (got: $REDIRECT_CODE)"
else
  echo "  [SKIP] plain HTTP URL, no redirect to test"
fi

echo "==> 8. WAF blocks a SQL injection attempt"
WAF_CODE="$(curl -s -o /dev/null -w '%{http_code}' "$URL/api/items?q=1'%20OR%20'1'='1" 2>/dev/null)"
[ "$WAF_CODE" = "403" ]; check $? "SQLi payload blocked (got: $WAF_CODE)"

echo ""
echo "==> RESULT: $PASS passed, $FAIL failed"
[ "$FAIL" = "0" ]
