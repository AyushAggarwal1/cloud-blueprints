# 1. Create Label (Replaces labels.py)
resource "terracurl_request" "create_label" {
  name    = "cspm_create_label"
  url     = "${var.cspm_url}/labels"
  method  = "POST"

  headers = {
    Authorization = "Bearer ${var.cspm_token}"
    Content-Type  = "application/json"
  }

  request_body = jsonencode({
    name       = var.label_name
    aws_prefix = var.aws_prefix
  })

  response_codes = [200, 201]
}

# 2. Create Tag (Replaces labels.py)
resource "terracurl_request" "create_tag" {
  name    = "cspm_create_tag"
  url     = "${var.cspm_url}/tags"
  method  = "POST"

  headers = {
    Authorization = "Bearer ${var.cspm_token}"
    Content-Type  = "application/json"
  }

  request_body = jsonencode({
    value = var.tag_value
  })

  response_codes = [200, 201]
}

# 3. Onboard GCP Projects (Replaces tf_onboard.py)
resource "terracurl_request" "onboard_gcp_project" {
  for_each = toset(var.target_project_ids)

  name    = "cspm_onboard_${each.key}"
  url     = "${var.cspm_url}/google-cloud-create"
  method  = "POST"

  headers = {
    Authorization = "Bearer ${var.cspm_token}"
    Content-Type  = "application/json"
  }

  # Explicit dependency to ensure Infrastructure and Labels exist first
  depends_on = [
    google_service_account_key.default,
    google_organization_iam_member.custom_role_assignment,
    terracurl_request.create_label,
    terracurl_request.create_tag
  ]

  request_body = jsonencode({
    project_id      = each.key
    # FIX: Changed 'service_account' to 'client_email' to resolve the 400 error.
    client_email    = google_service_account.service_account.email 
    # Terraform handles the base64 decoding of the key automatically here
    private_key     = base64decode(google_service_account_key.default.private_key)
    label           = jsondecode(terracurl_request.create_label.response).id
    tag             = jsondecode(terracurl_request.create_tag.response).id
    scan_asset_type = var.scan_asset_type
  })

  response_codes = [200, 201]
}