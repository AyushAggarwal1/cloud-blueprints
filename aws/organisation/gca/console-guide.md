# Manual console setup — CNAPPOrgSecurityAuditor role

For customers who don't want to run CloudFormation, Terraform, or scripts.
No IaC tool required — just the IAM console. Repeat this once per account
(management account, then each member account you want AccuKnox to audit).

Equivalent to: `aws-org-cf-demo-6e53.yaml`

## What you're creating

An IAM role that AccuKnox's audit user assumes read-only, to scan security
posture and list AI/ML resources. Nothing it does is destructive — the
attached policies are read-only (`ReadOnlyAccess`, `SecurityAudit`, and a
small Bedrock/SageMaker read/invoke policy).

## Steps

1. Sign in to the account (management account or member account) and open
   **IAM → Roles → Create role**.
2. Under **Trusted entity type**, choose **Custom trust policy** and paste:

   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "AWS": "arn:aws:iam::735362266271:user/cnapp-security-audit-ak"
         },
         "Action": "sts:AssumeRole",
         "Condition": {
           "StringEquals": {
             "sts:ExternalId": "<the external ID AccuKnox gave you>"
           }
         }
       }
     ]
   }
   ```

   The External ID is a shared secret — it prevents anyone else who
   guesses the AccuKnox account ARN from assuming this role ("confused
   deputy" protection). Use the exact value your AccuKnox contact gave you.

3. On **Add permissions**, attach these two AWS-managed policies:
   - `ReadOnlyAccess`
   - `SecurityAudit`
4. Click **Next**, name the role exactly `CNAPPOrgSecurityAuditor`, and set
   **Description** to `CNAPPOrgSecurityAuditor`.
5. Under **Maximum session duration**, change it from the 1-hour default to
   **12 hours** (43200 seconds) — Edit this on the role's **Summary** page
   after creation if the create wizard doesn't expose it.
6. Create the role, then open it and add one more **inline policy** named
   `AI-ML-permissions`:

   ```json
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
   ```

7. Confirm the role's ARN is `arn:aws:iam::<this account id>:role/CNAPPOrgSecurityAuditor`
   and share it (or just the account ID) with AccuKnox.

## Rolling out to every member account

Doing this by hand in every account in an AWS Organization does not scale
past a handful of accounts. For anything beyond that, use
[`deploy-org-security-auditor.sh`](./deploy-org-security-auditor.sh) in this
folder — it's plain `aws` CLI calls (no CloudFormation StackSet, no
Terraform, no state file), so every command it runs is visible and
auditable before you execute it.

## Removing the role later

IAM → Roles → search `CNAPPOrgSecurityAuditor` → **Delete**. Repeat per
account. There is no stack or state to clean up because none was created.
