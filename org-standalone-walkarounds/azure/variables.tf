# --- Azure Variables ---
variable "application_name" {
  type        = string
  description = "The display name of the Azure AD Application"
  default     = "ak-sp-app"
}

variable "subscription_ids" {
  type        = list(string)
  description = "List of Azure Subscription IDs to onboard"
}

# --- CSPM API Variables ---
variable "cspm_token" {
  type        = string
  description = "Bearer token for AccuKnox CSPM API Authorization"
  sensitive   = true
}

variable "cspm_url" {
  type        = string
  description = "Base URL for the CSPM API"
  default     = "https://cspm.accuknox.com/api/v1"
}

variable "label_name" {
  type        = string
  description = "Name of the label to create in CSPM"
  default     = "azdev"
}

variable "aws_prefix" {
  type        = string
  description = "The 'aws_prefix' parameter required by the CSPM Label API"
  default     = "azdev"
}

variable "tag_value" {
  type        = string
  description = "Value of the tag to create in CSPM"
  default     = "azdev"
}

variable "scan_asset_type" {
  type        = string
  description = "Asset type to scan (e.g., GCA or AI/ML)"
  default     = "GCA"
}