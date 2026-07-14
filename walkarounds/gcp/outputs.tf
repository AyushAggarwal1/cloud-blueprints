output "service_account_email" {
  description = "The email of the created Service Account"
  value       = google_service_account.service_account.email
}

output "cspm_label_id" {
  description = "The ID of the Label created in CSPM"
  value       = jsondecode(terracurl_request.create_label.response).id
}

output "cspm_tag_id" {
  description = "The ID of the Tag created in CSPM"
  value       = jsondecode(terracurl_request.create_tag.response).id
}

output "onboarded_projects" {
  description = "List of projects attempted to onboard"
  value       = var.target_project_ids
}