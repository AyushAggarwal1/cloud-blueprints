variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "shaped-infusion-402417"  # set default or pass via -var
}
variable "service_account_id" {
  description = "Service Account ID"
  type        = string
  default     = "gcp-aiml-onboarding-sa"
}
variable "service_account_display_name" {
  description = "Display Name for the Service Account"
  type        = string
  default     = "GCP-AIML-Onboarding-SA"
}

provider "google" {
  project = project-id
}

resource "google_service_account" "service_account" {
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
}

resource "google_project_iam_member" "viewer_role" {
  project = project-id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}
resource "google_project_iam_member" "security_reviewer" {
  project = project-id
  role    = "roles/iam.securityReviewer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "vertex_ai_viewer" {
  project = project-id
  role    = "roles/aiplatform.viewer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_member" "storage_bucket_viewer" {
  project = project-id
  role    = "roles/storage.bucketViewer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}
resource "google_project_iam_member" "storage_object_viewer" {
  project = project-id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "google_project_iam_custom_role" "custom_storage_iam_role" {
  project     = project-id
  role_id     = "custom_storage_get_policy_role"
  title       = "Custom role for storage buckets getIamPolicy"
  description = "Allows reading bucket IAM policy"
  permissions = ["storage.buckets.getIamPolicy"]
}

resource "google_project_iam_custom_role" "predict_role" {
  project     = project-id
  role_id     = "custom_vertex_ai_predict_role"
  title       = "Custom role for Vertex AI predict"
  description = "Allows aiplatform.endpoints.predict only"
  permissions = ["aiplatform.endpoints.predict"]
}

resource "google_project_iam_member" "custom_storage_role_binding" {
  project = project-id
  role    = google_project_iam_custom_role.custom_storage_iam_role.name
  member  = "serviceAccount:${google_service_account.service_account.email}"
}
resource "google_project_iam_member" "custom_predict_role_binding" {
  project = project-id
  role    = google_project_iam_custom_role.predict_role.name
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

resource "null_resource" "save_key_locally" {
  depends_on = [google_service_account.service_account]
  provisioner "local-exec" {
    command = "gcloud iam service-accounts keys create service_account_key.json --iam-account=${google_service_account.service_account.email}"
  }
}

output "service_account_email" {
  value = google_service_account.service_account.email
}
output "key_file_path" {
  value = "service_account_key.json"
}