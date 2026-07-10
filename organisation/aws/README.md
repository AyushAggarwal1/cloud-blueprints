- Role ARN
`arn:aws:iam::{{account_no}}:user/cnapp-security-audit-ak`

- Identity
`aws sts get-caller-identity`

- Assume Role
```code
 aws sts assume-role \
  --role-arn "arn:aws:iam::{{account_no}}:role/CNAPPOrgSecurityAuditor" \
  --role-session-name verification \
  --external-id "a3e59187-a583-a9a9-6b1f-db00b08249ec" \
  --duration-seconds 43200
```