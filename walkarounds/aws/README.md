# AccuKnox AWS Security Audit Terraform

Deploys AccuKnox security auditor roles across AWS Organizations using CloudFormation StackSets and automatically onboards the accounts via AccuKnox API.

## Setup

1. **Configure variables**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Initialize and apply**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Required Variables

- `aws_profile` - AWS profile for management account
- `root_organizational_unit_id` - AWS Organization root OU ID (e.g., "r-xxxxx")
- `accuknox_api_token` - AccuKnox API authentication token
- `accuknox_api_base_url` - AccuKnox API URL (stage/prod environment)
- `accuknox_label` - AccuKnox label UUID
- `accuknox_tag` - AccuKnox tag UUID

## Account Filtering

- `account_filter_type` - "NONE", "INCLUDE", or "EXCLUDE"
- `target_account_ids` - List of account IDs for filtering
- `organizational_unit_ids` - Specific OUs to deploy to (empty = root OU)

## Templates

- Dev: `aws-org-cf-dev-6cad.yaml`
- Prod: `aws-org-cf-prod-6cad.yaml`

Update `cloudformation_template_url` variable for different environments.