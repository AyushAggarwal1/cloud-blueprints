variable "aws_profile" {
  description = "AWS profile to use for authentication."
  type        = string
  default     = "default"
}

variable "management_account_region" {
  description = "AWS region where the management account stack runs."
  type        = string
  default     = "us-east-1"
}

variable "root_organizational_unit_id" {
  description = "Root organizational unit ID for the AWS Organization."
  type        = string
  default     = ""
}

variable "organizational_unit_ids" {
  description = "List of specific organizational unit IDs where the StackSet will be deployed."
  type        = list(string)
  default     = []
}

variable "deployment_regions" {
  description = "Regions where StackSet instances are created."
  type        = list(string)
  default = ["us-east-1"]
}

variable "auto_deploy" {
  description = "Enable automatic StackSet deployment to new organization accounts."
  type        = bool
  default     = true
}

variable "account_filter_type" {
  description = "Filter behavior for StackSet deployment targets."
  type        = string
  default     = "NONE"

  validation {
    condition     = contains(["NONE", "INCLUDE", "EXCLUDE"], var.account_filter_type)
    error_message = "account_filter_type must be one of NONE, INCLUDE, or EXCLUDE."
  }
}

variable "target_account_ids" {
  description = "Specific account IDs used when filtering StackSet deployments."
  type        = list(string)
  default     = []
}

variable "external_id" {
  description = "External ID used when AccuKnox assumes the security auditor role. Leave empty to auto-generate a UUID."
  type        = string
  default     = ""
  sensitive   = true
}

variable "accuknox_api_base_url" {
  description = "Base URL for the AccuKnox API."
  type        = string
  default     = "https://cspm.accuknox.com"
}

variable "accuknox_api_path" {
  description = "Path for the AccuKnox onboarding endpoint."
  type        = string
  default     = "/api/v1/organizations"
}

variable "accuknox_api_token" {
  description = "Bearer token used to authenticate against the AccuKnox API."
  type        = string
  default     = ""
  sensitive   = true
}

variable "accuknox_label" {
  description = "Label applied to the organization onboarding request."
  type        = string
  default     = ""
}

variable "accuknox_tag" {
  description = "Tag identifier included in the onboarding request."
  type        = string
  default     = ""
}

variable "accuknox_scan_asset_type" {
  description = "Asset type used for the scan when onboarding."
  type        = string
  default     = "GCA"
}

variable "accuknox_account_selection_type" {
  description = "Account selection mode sent to the onboarding API."
  type        = string
  default     = "ALL"
}

variable "accuknox_auto_connect_new_accounts" {
  description = "Automatically connect accounts created after onboarding."
  type        = bool
  default     = false
}

variable "accuknox_onboarding_method" {
  description = "Onboarding method passed to the API."
  type        = string
  default     = "ROLE_ARN"
}

variable "accuknox_explicit_ou_list" {
  description = "Override list of OUs supplied to the onboarding API. Defaults to OUs beyond the root."
  type        = list(string)
  default     = []
}

variable "cloudformation_template_url" {
  description = "S3 URL for the CloudFormation template used to deploy the security auditor stack."
  type        = string
  default     = ""
}


