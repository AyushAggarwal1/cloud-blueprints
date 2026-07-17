"""
Lambda handler that reacts to AWS Organizations "new account" events
(CreateAccountResult, MoveAccount) and creates/updates the
CNAPPOrgSecurityAuditor role in the account, using direct IAM API calls.

This is the event-driven equivalent of the AutoDeployment feature on the
CloudFormation StackSet in aws-org-cf-demo-6e53.yaml, without using
CloudFormation. Deployed by ../deploy-auto-onboarding.sh.
"""

import json
import os
import time

import boto3
from botocore.exceptions import ClientError

ROLE_NAME = os.environ.get("ROLE_NAME", "CNAPPOrgSecurityAuditor")
EXTERNAL_ID = os.environ["EXTERNAL_ID"]
TRUSTED_ACCOUNT = os.environ.get("TRUSTED_ACCOUNT", "735362266271")
TRUSTED_PRINCIPAL_USER = os.environ.get("TRUSTED_PRINCIPAL_USER", "cnapp-security-audit-ak")
MEMBER_ASSUME_ROLE_NAME = os.environ.get("MEMBER_ASSUME_ROLE_NAME", "OrganizationAccountAccessRole")
TARGET_OU_IDS = [ou.strip() for ou in os.environ.get("TARGET_OU_IDS", "").split(",") if ou.strip()]

orgs = boto3.client("organizations")
sts = boto3.client("sts")

TRUST_POLICY = {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {"AWS": f"arn:aws:iam::{TRUSTED_ACCOUNT}:user/{TRUSTED_PRINCIPAL_USER}"},
            "Action": "sts:AssumeRole",
            "Condition": {"StringEquals": {"sts:ExternalId": EXTERNAL_ID}},
        }
    ],
}

AIML_POLICY = {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowAIMLServices",
            "Effect": "Allow",
            "Action": [
                "bedrock:InvokeModel",
                "bedrock:ListImportedModels",
                "bedrock:ListModelInvocationJobs",
                "sagemaker:InvokeEndpoint",
            ],
            "Resource": "*",
        }
    ],
}


def extract_account_id(event):
    detail = event.get("detail", {})
    event_name = detail.get("eventName")

    if event_name == "CreateAccountResult":
        status = detail.get("serviceEventDetails", {}).get("createAccountStatus", {})
        return status.get("accountId"), event_name

    if event_name == "MoveAccount":
        params = detail.get("requestParameters", {})
        return params.get("accountId"), event_name

    return None, event_name


def is_in_target_scope(account_id):
    if not TARGET_OU_IDS:
        return True

    try:
        parents = orgs.list_parents(ChildId=account_id)["Parents"]
    except ClientError as exc:
        print(f"WARNING: could not list parents for {account_id}: {exc}")
        return False

    seen = set()
    while parents:
        parent = parents[0]
        parent_id = parent["Id"]
        if parent_id in TARGET_OU_IDS:
            return True
        if parent["Type"] != "ORGANIZATIONAL_UNIT" or parent_id in seen:
            break
        seen.add(parent_id)
        parents = orgs.list_parents(ChildId=parent_id)["Parents"]

    return False


def assume_member_role(account_id, retries=5, delay_seconds=10):
    role_arn = f"arn:aws:iam::{account_id}:role/{MEMBER_ASSUME_ROLE_NAME}"
    last_error = None
    for attempt in range(1, retries + 1):
        try:
            resp = sts.assume_role(RoleArn=role_arn, RoleSessionName="cnapp-auditor-auto-onboard")
            return resp["Credentials"]
        except ClientError as exc:
            last_error = exc
            print(f"assume-role attempt {attempt}/{retries} into {account_id} failed: {exc}")
            time.sleep(delay_seconds)
    raise last_error


def create_or_update_role(account_id):
    creds = assume_member_role(account_id)
    iam = boto3.client(
        "iam",
        aws_access_key_id=creds["AccessKeyId"],
        aws_secret_access_key=creds["SecretAccessKey"],
        aws_session_token=creds["SessionToken"],
    )

    try:
        iam.get_role(RoleName=ROLE_NAME)
        iam.update_assume_role_policy(RoleName=ROLE_NAME, PolicyDocument=json.dumps(TRUST_POLICY))
        print(f"[{account_id}] role already existed, trust policy refreshed")
    except iam.exceptions.NoSuchEntityException:
        iam.create_role(
            RoleName=ROLE_NAME,
            Path="/",
            Description="CNAPPOrgSecurityAuditor",
            MaxSessionDuration=43200,
            AssumeRolePolicyDocument=json.dumps(TRUST_POLICY),
        )
        print(f"[{account_id}] role created")

    iam.attach_role_policy(RoleName=ROLE_NAME, PolicyArn="arn:aws:iam::aws:policy/ReadOnlyAccess")
    iam.attach_role_policy(RoleName=ROLE_NAME, PolicyArn="arn:aws:iam::aws:policy/SecurityAudit")
    iam.put_role_policy(
        RoleName=ROLE_NAME,
        PolicyName="AI-ML-permissions",
        PolicyDocument=json.dumps(AIML_POLICY),
    )


def handler(event, context):
    print("event:", json.dumps(event))

    account_id, event_name = extract_account_id(event)
    if not account_id:
        print(f"no account id found for event {event_name}, ignoring")
        return {"status": "ignored", "reason": "no_account_id"}

    if not is_in_target_scope(account_id):
        print(f"account {account_id} is outside TARGET_OU_IDS, ignoring")
        return {"status": "ignored", "reason": "out_of_scope", "accountId": account_id}

    create_or_update_role(account_id)
    return {"status": "ok", "accountId": account_id, "triggeredBy": event_name}
