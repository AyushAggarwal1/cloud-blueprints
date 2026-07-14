# AWS Provider Configuration
provider "aws" {
  profile = var.aws_profile
  region  = var.management_account_region
}

# Generate a random UUID for external ID if not provided
resource "random_uuid" "external_id" {
  count = var.external_id == "" ? 1 : 0
}

resource "aws_cloudformation_stack" "ak_security_audit" {
  name         = "ak-security-audit"
  template_url = var.cloudformation_template_url

  capabilities = ["CAPABILITY_NAMED_IAM"]

  parameters = {
    AutoDeploy            = local.auto_deploy_parameter
    OrganizationalUnitIds = local.ou_ids_parameter
    Regions               = local.regions_parameter
    AccountFilterType     = var.account_filter_type
    AccountIds            = local.account_ids_parameter
    ExternalId            = local.external_id
  }

  tags = {
    ManagedBy = "Terraform"
  }
}

# Automatically onboard the AWS account to AccuKnox using terracurl data source
data "terracurl_request" "accuknox_onboarding" {
  depends_on = [aws_cloudformation_stack.ak_security_audit]

  # Only execute if API token is provided
  count = var.accuknox_api_token != "" ? 1 : 0

  name   = "accuknox-aws-onboarding"
  url    = local.accuknox_request_url
  method = "POST"

  headers = local.accuknox_request_headers

  request_body = local.accuknox_request_body

  response_codes = [200, 201, 202]
}
