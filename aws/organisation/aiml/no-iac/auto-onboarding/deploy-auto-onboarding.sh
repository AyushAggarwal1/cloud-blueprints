#!/usr/bin/env bash
#
# Wires up event-driven auto-onboarding for the CNAPPOrgSecurityAuditor role:
# an EventBridge rule watches AWS Organizations for CreateAccountResult /
# MoveAccount events and invokes a Lambda function that creates the role in
# the new/moved account. This is the plain-CLI equivalent of the
# StackSet's AutoDeployment feature, without CloudFormation.
#
# Every resource it creates (IAM role, Lambda function, EventBridge rule) is
# a plain, individually-inspectable object in the console -- nothing is
# bundled into a stack.
#
# Prerequisite: run once in the management account, after the base role has
# already been created there and in existing member accounts (see
# ../deploy-org-security-auditor.sh).
#
# Prerequisite: at least one CloudTrail trail must exist in the management
# account capturing management events, for Organizations events to reach
# EventBridge. This is a native AWS requirement, unrelated to CloudFormation
# vs. scripts -- StackSets' AutoDeployment relies on the same underlying
# event stream internally.
#
# Usage:
#   ./deploy-auto-onboarding.sh \
#     --external-id "<random-string-from-AccuKnox>" \
#     --ou-ids "ou-abcd-11111111,ou-abcd-22222222" \
#     [--trusted-account 735362266271] \
#     [--member-role-name OrganizationAccountAccessRole]

set -euo pipefail

FUNCTION_NAME="cnapp-auditor-auto-onboard"
EXEC_ROLE_NAME="cnapp-auditor-auto-onboard-lambda-role"
RULE_NAME="cnapp-auditor-new-account-rule"
TRUSTED_ACCOUNT="735362266271"
MEMBER_ASSUME_ROLE="OrganizationAccountAccessRole"
EXTERNAL_ID=""
OU_IDS=""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() { grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --external-id) EXTERNAL_ID="$2"; shift 2 ;;
    --ou-ids) OU_IDS="$2"; shift 2 ;;
    --trusted-account) TRUSTED_ACCOUNT="$2"; shift 2 ;;
    --member-role-name) MEMBER_ASSUME_ROLE="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown argument: $1"; usage ;;
  esac
done

[[ -z "$EXTERNAL_ID" ]] && { echo "ERROR: --external-id is required"; exit 1; }
[[ -z "$OU_IDS" ]] && { echo "ERROR: --ou-ids is required"; exit 1; }

ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
REGION=$(aws configure get region)

echo "== Packaging Lambda =="
BUILD_DIR=$(mktemp -d)
cp "$SCRIPT_DIR/lambda/create_auditor_role.py" "$BUILD_DIR/"
(cd "$BUILD_DIR" && zip -q -r function.zip create_auditor_role.py)

echo "== Creating Lambda execution role =="
EXEC_TRUST_POLICY='{
  "Version": "2012-10-17",
  "Statement": [
    {"Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}
  ]
}'

if aws iam get-role --role-name "$EXEC_ROLE_NAME" >/dev/null 2>&1; then
  echo "execution role already exists, reusing"
else
  aws iam create-role \
    --role-name "$EXEC_ROLE_NAME" \
    --assume-role-policy-document "$EXEC_TRUST_POLICY" >/dev/null
  echo "waiting for IAM role propagation..."
  sleep 10
fi

EXEC_ROLE_ARN=$(aws iam get-role --role-name "$EXEC_ROLE_NAME" --query 'Role.Arn' --output text)

aws iam attach-role-policy --role-name "$EXEC_ROLE_NAME" \
  --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

EXEC_INLINE_POLICY=$(cat <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AssumeIntoMemberAccounts",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::*:role/${MEMBER_ASSUME_ROLE}"
    },
    {
      "Sid": "ReadOrganizationStructure",
      "Effect": "Allow",
      "Action": [
        "organizations:ListParents",
        "organizations:DescribeAccount",
        "organizations:ListAccountsForParent"
      ],
      "Resource": "*"
    }
  ]
}
JSON
)

aws iam put-role-policy --role-name "$EXEC_ROLE_NAME" \
  --policy-name "cnapp-auditor-auto-onboard-permissions" \
  --policy-document "$EXEC_INLINE_POLICY"

echo "== Creating/updating Lambda function =="
if aws lambda get-function --function-name "$FUNCTION_NAME" >/dev/null 2>&1; then
  aws lambda update-function-code \
    --function-name "$FUNCTION_NAME" \
    --zip-file "fileb://$BUILD_DIR/function.zip" >/dev/null
  aws lambda update-function-configuration \
    --function-name "$FUNCTION_NAME" \
    --environment "Variables={EXTERNAL_ID=${EXTERNAL_ID},TRUSTED_ACCOUNT=${TRUSTED_ACCOUNT},MEMBER_ASSUME_ROLE_NAME=${MEMBER_ASSUME_ROLE},TARGET_OU_IDS=${OU_IDS}}" >/dev/null
else
  # Lambda needs a moment after IAM role creation before it will accept the role
  for i in $(seq 1 6); do
    if aws lambda create-function \
      --function-name "$FUNCTION_NAME" \
      --runtime python3.12 \
      --role "$EXEC_ROLE_ARN" \
      --handler create_auditor_role.handler \
      --timeout 120 \
      --memory-size 256 \
      --zip-file "fileb://$BUILD_DIR/function.zip" \
      --environment "Variables={EXTERNAL_ID=${EXTERNAL_ID},TRUSTED_ACCOUNT=${TRUSTED_ACCOUNT},MEMBER_ASSUME_ROLE_NAME=${MEMBER_ASSUME_ROLE},TARGET_OU_IDS=${OU_IDS}}" \
      >/dev/null 2>&1; then
      break
    fi
    echo "lambda create-function not ready yet, retrying in 10s ($i/6)..."
    sleep 10
  done
fi

FUNCTION_ARN=$(aws lambda get-function --function-name "$FUNCTION_NAME" --query 'Configuration.FunctionArn' --output text)

echo "== Creating EventBridge rule =="
EVENT_PATTERN=$(cat <<'JSON'
{
  "source": ["aws.organizations"],
  "detail": {
    "eventName": ["CreateAccountResult", "MoveAccount"]
  }
}
JSON
)

aws events put-rule \
  --name "$RULE_NAME" \
  --event-pattern "$EVENT_PATTERN" \
  --state ENABLED >/dev/null

aws lambda add-permission \
  --function-name "$FUNCTION_NAME" \
  --statement-id "AllowEventBridgeInvoke" \
  --action "lambda:InvokeFunction" \
  --principal "events.amazonaws.com" \
  --source-arn "arn:aws:events:${REGION}:${ACCOUNT_ID}:rule/${RULE_NAME}" \
  >/dev/null 2>&1 || echo "(permission already granted, skipping)"

aws events put-targets \
  --rule "$RULE_NAME" \
  --targets "Id"="1","Arn"="$FUNCTION_ARN" >/dev/null

echo
echo "Done. New accounts created in or moved into: $OU_IDS"
echo "will automatically get the CNAPPOrgSecurityAuditor role within a few minutes of the event."
echo
echo "To test manually: aws lambda invoke --function-name $FUNCTION_NAME --payload '{}' /tmp/out.json && cat /tmp/out.json"

rm -rf "$BUILD_DIR"
