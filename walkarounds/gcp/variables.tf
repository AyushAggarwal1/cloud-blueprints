# --- GCP Configuration ---

variable "org_id" {
  type        = string
  description = "The Google Cloud Organization ID where roles and bindings will be applied"
}

variable "host_project_id" {
  type        = string
  description = "The Project ID where the Service Account will be created (Host Project)"
}

variable "target_project_ids" {
  type        = list(string)
  description = "List of GCP Project IDs to scan/onboard (Replaces project_id.txt)"
}

# --- CSPM API Configuration ---

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
  default     = "gcpdev"
}

variable "aws_prefix" {
  type        = string
  description = "The 'aws_prefix' parameter for the label (API requirement)"
  default     = "gcpdev"
}

variable "tag_value" {
  type        = string
  description = "Value of the tag to create in CSPM"
  default     = "gcpdev"
}

variable "scan_asset_type" {
  type        = string
  description = "Asset type to scan (e.g., GCA or AI/ML)"
  default     = "GCA"
}