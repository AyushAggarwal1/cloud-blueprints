# CNAPPOrgSecurityAuditor without CloudFormation or Terraform

Equivalent to `../aws-org-cf-demo-6e53.yaml`, for customers who don't want
to run CloudFormation or Terraform. Nothing here creates a stack or a state
file -- every resource (IAM role, Lambda, EventBridge rule) is created
individually via plain `aws` CLI calls and can be inspected in the console
like any other resource.

## Pieces

1. **`console-guide.md`** -- manual IAM console steps, one account at a time.
2. **`deploy-org-security-auditor.sh`** -- one-time/on-demand script that
   creates the role in the management account and in every existing member
   account across the given OUs. Re-run it whenever you want to sweep for
   accounts that don't have the role yet.
3. **`auto-onboarding/`** -- optional event-driven layer so *future* accounts
   (newly created or moved into a watched OU) get the role automatically,
   without re-running step 2 by hand. This is the plain-CLI equivalent of
   the CloudFormation StackSet's `AutoDeployment: Enabled` setting.

## Recommended order

```
./deploy-org-security-auditor.sh --external-id "<id>" --ou-ids "ou-...,ou-..."
./auto-onboarding/deploy-auto-onboarding.sh --external-id "<id>" --ou-ids "ou-...,ou-..."
```

Step 1 covers accounts that exist today. Step 2 covers accounts that show up
tomorrow. Both are idempotent -- re-running either is safe and just
refreshes the role/trust policy.

## Auto-onboarding: how it works and its limits

- An EventBridge rule in the management account watches for AWS
  Organizations `CreateAccountResult` and `MoveAccount` events.
- A Lambda function reacts by assuming into the new/moved account
  (`OrganizationAccountAccessRole` by default) and creating the
  `CNAPPOrgSecurityAuditor` role there, scoped to `TARGET_OU_IDS`.
- **Requires an existing CloudTrail trail** in the management account
  capturing management events -- without one, Organizations events never
  reach EventBridge. Most AWS Organizations already have this; check
  CloudTrail console before relying on auto-onboarding. This isn't a
  CloudFormation/Terraform requirement, it's how EventBridge receives any
  CloudTrail-sourced event.
- New accounts get the role within a few minutes of creation (async
  propagation of the CloudTrail event), not instantly.
- If `OrganizationAccountAccessRole` hasn't propagated into a brand-new
  account yet, the Lambda retries with backoff before giving up; check
  CloudWatch Logs for `/aws/lambda/cnapp-auditor-auto-onboard` if an account
  doesn't get the role.
- Accounts invited into the org via handshake (rather than created directly)
  aren't covered yet -- only `CreateAccountResult` and `MoveAccount`. Ask if
  you need that path too.

## Removing everything

```
aws events remove-targets --rule cnapp-auditor-new-account-rule --ids 1
aws events delete-rule --name cnapp-auditor-new-account-rule
aws lambda delete-function --function-name cnapp-auditor-auto-onboard
aws iam detach-role-policy --role-name cnapp-auditor-auto-onboard-lambda-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam delete-role-policy --role-name cnapp-auditor-auto-onboard-lambda-role \
  --policy-name cnapp-auditor-auto-onboard-permissions
aws iam delete-role --role-name cnapp-auditor-auto-onboard-lambda-role
```

Then remove `CNAPPOrgSecurityAuditor` per account as described in
`console-guide.md`.
