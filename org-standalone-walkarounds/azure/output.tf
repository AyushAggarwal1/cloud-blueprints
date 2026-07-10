output "application_client_id" {
  value = azuread_application.app.client_id
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

output "generated_label_id" {
  description = "The ID of the label created in CSPM"
  value       = jsondecode(terracurl_request.create_label.response).id
}

output "generated_tag_id" {
  description = "The ID of the tag created in CSPM"
  value       = jsondecode(terracurl_request.create_tag.response).id
}

output "onboarded_subscriptions" {
  value = var.subscription_ids
}