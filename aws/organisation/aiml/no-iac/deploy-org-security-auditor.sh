#!/usr/bin/env bash
#
# Creates the CNAPPOrgSecurityAuditor IAM role in the AWS Organizations
# management account and replicates it into member accounts, using only
# plain AWS CLI calls (no CloudFormation, no Terraform, no state file).
#
# Equivalent to: aws-org-cf-demo-6e53.yaml
#
# Requires: aws cli v2, jq, credentials for the management account with
# organizations:ListAccountsForParent / organizations:ListAccounts and
# sts:AssumeRole into member accounts (default: OrganizationAccountAccessRole).
#
# Usage:
#   ./deploy-org-security-auditor.sh \
#     --external-id "<random-string-from-AccuKnox>" \
#     --ou-ids "ou-abcd-11111111,ou-abcd-22222222" \
#     [--trusted-account 735362266271] \
#     [--member-role-name OrganizationAccountAccessRole] \
#     [--include accountId1,accountId2] \
#     [--exclude accountId3,accountId4] \
#     [--dry-run]

set -euo pipefail

ROLE_NAME="CNAPPOrgSecurityAuditor"
TRUSTED_ACCOUNT="735362266271"
TRUSTED_PRINCIPAL_USER="cnapp-security-audit-ak"
MEMBER_ASSUME_ROLE="OrganizationAccountAccessRole"
EXTERNAL_ID=""
OU_IDS=""
INCLUDE_ACCOUNTS=""
EXCLUDE_ACCOUNTS=""
DRY_RUN="false"

usage() { grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --external-id) EXTERNAL_ID="$2"; shift 2 ;;
    --ou-ids) OU_IDS="$2"; shift 2 ;;
    --trusted-account) TRUSTED_ACCOUNT="$2"; shift 2 ;;
    --member-role-name) MEMBER_ASSUME_ROLE="$2"; shift 2 ;;
    --include) INCLUDE_ACCOUNTS="$2"; shift 2 ;;
    --exclude) EXCLUDE_ACCOUNTS="$2"; shift 2 ;;
    --dry-run) DRY_RUN="true"; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown argument: $1"; usage ;;
  esac
done

[[ -z "$EXTERNAL_ID" ]] && { echo "ERROR: --external-id is required"; exit 1; }
[[ -z "$OU_IDS" ]] && { echo "ERROR: --ou-ids is required"; exit 1; }

TRUST_POLICY=$(cat <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::${TRUSTED_ACCOUNT}:user/${TRUSTED_PRINCIPAL_USER}" },
      "Action": "sts:AssumeRole",
      "Condition": { "StringEquals": { "sts:ExternalId": "${EXTERNAL_ID}" } }
    }
  ]
}
JSON
)

AIML_POLICY=$(cat <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAIMLServices",
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:ListImportedModels",
        "bedrock:ListModelInvocationJobs",
        "sagemaker:InvokeEndpoint"
      ],
      "Resource": "*"
    }
  ]
}
JSON
)

create_role_in_current_credentials() {
  local label="$1"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] would create role ${ROLE_NAME} in ${label}"
    return
  fi

  if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
    echo "[${label}] role ${ROLE_NAME} already exists, updating trust policy"
    aws iam update-assume-role-policy \
      --role-name "$ROLE_NAME" \
      --policy-document "$TRUST_POLICY"
  else
    echo "[${label}] creating role ${ROLE_NAME}"
    aws iam create-role \
      --role-name "$ROLE_NAME" \
      --path "/" \
      --description "CNAPPOrgSecurityAuditor" \
      --max-session-duration 43200 \
      --assume-role-policy-document "$TRUST_POLICY" >/dev/null
  fi

  aws iam attach-role-policy --role-name "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/ReadOnlyAccess"
  aws iam attach-role-policy --role-name "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/SecurityAudit"
  aws iam put-role-policy --role-name "$ROLE_NAME" \
    --policy-name "AI-ML-permissions" \
    --policy-document "$AIML_POLICY"

  echo "[${label}] done: $(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)"
}

echo "== Management account =="
create_role_in_current_credentials "management account"

echo
echo "== Enumerating accounts in target OUs =="
ALL_ACCOUNT_IDS=()
IFS=',' read -ra OU_ARRAY <<< "$OU_IDS"
for ou in "${OU_ARRAY[@]}"; do
  ou_trimmed=$(echo "$ou" | xargs)
  echo "OU: $ou_trimmed"
  mapfile -t ids < <(aws organizations list-accounts-for-parent \
    --parent-id "$ou_trimmed" \
    --query 'Accounts[?Status==`ACTIVE`].Id' --output text | tr '\t' '\n')
  ALL_ACCOUNT_IDS+=("${ids[@]}")
done

# de-duplicate
mapfile -t ALL_ACCOUNT_IDS < <(printf '%s\n' "${ALL_ACCOUNT_IDS[@]}" | sort -u)

if [[ -n "$INCLUDE_ACCOUNTS" ]]; then
  IFS=',' read -ra KEEP <<< "$INCLUDE_ACCOUNTS"
  mapfile -t ALL_ACCOUNT_IDS < <(comm -12 \
    <(printf '%s\n' "${ALL_ACCOUNT_IDS[@]}" | sort) \
    <(printf '%s\n' "${KEEP[@]}" | sort))
fi

if [[ -n "$EXCLUDE_ACCOUNTS" ]]; then
  IFS=',' read -ra DROP <<< "$EXCLUDE_ACCOUNTS"
  mapfile -t ALL_ACCOUNT_IDS < <(comm -23 \
    <(printf '%s\n' "${ALL_ACCOUNT_IDS[@]}" | sort) \
    <(printf '%s\n' "${DROP[@]}" | sort))
fi

echo "Target member accounts: ${ALL_ACCOUNT_IDS[*]:-none}"
echo

MGMT_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

for account_id in "${ALL_ACCOUNT_IDS[@]}"; do
  [[ "$account_id" == "$MGMT_ACCOUNT_ID" ]] && continue

  echo "== Member account ${account_id} =="
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] would assume ${MEMBER_ASSUME_ROLE} into ${account_id} and create role"
    continue
  fi

  creds=$(aws sts assume-role \
    --role-arn "arn:aws:iam::${account_id}:role/${MEMBER_ASSUME_ROLE}" \
    --role-session-name "cnapp-auditor-rollout" \
    --output json)

  export AWS_ACCESS_KEY_ID=$(echo "$creds" | jq -r '.Credentials.AccessKeyId')
  export AWS_SECRET_ACCESS_KEY=$(echo "$creds" | jq -r '.Credentials.SecretAccessKey')
  export AWS_SESSION_TOKEN=$(echo "$creds" | jq -r '.Credentials.SessionToken')

  create_role_in_current_credentials "account ${account_id}"

  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
done

echo
echo "All done."
