# 1. Create the Label
resource "terracurl_request" "create_label" {
  name   = "cspm_create_label"
  url    = "${var.cspm_url}/labels"
  method = "POST"

  headers = {
    Authorization  = "Bearer ${var.cspm_token}"
    Content-Type   = "application/json"
    Accept         = "application/json"
  }

  request_body = jsonencode({
    name       = var.label_name
    aws_prefix = var.aws_prefix  # Using the renamed variable
  })

  response_codes = [200, 201]
}

# 2. Create the Tag
resource "terracurl_request" "create_tag" {
  name   = "cspm_create_tag"
  url    = "${var.cspm_url}/tags"
  method = "POST"

  headers = {
    Authorization  = "Bearer ${var.cspm_token}"
    Content-Type   = "application/json"
    Accept         = "application/json"
  }

  request_body = jsonencode({
    value = var.tag_value
  })

  response_codes = [200, 201]
}

# 3. Register Subscriptions
resource "terracurl_request" "onboard_subscription" {
  for_each = toset(var.subscription_ids)

  name   = "cspm_register_${each.key}"
  url    = "${var.cspm_url}/azure-cloud-create"
  method = "POST"

  headers = {
    Authorization  = "Bearer ${var.cspm_token}"
    Content-Type   = "application/json"
    Accept         = "application/json"
  }

  depends_on = [
    terracurl_request.create_label,
    terracurl_request.create_tag,
    azuread_application_password.secret,
    azurerm_role_assignment.assign_custom_role
  ]

  request_body = jsonencode({
    application_id  = azuread_application.app.client_id
    key_value       = azuread_application_password.secret.value
    subscription_id = each.key
    directory_id    = data.azurerm_client_config.current.tenant_id
    label           = jsondecode(terracurl_request.create_label.response).id
    tag             = jsondecode(terracurl_request.create_tag.response).id
    scan_asset_type = var.scan_asset_type
  })

  response_codes = [200, 201]
}