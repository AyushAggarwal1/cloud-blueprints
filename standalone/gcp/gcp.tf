variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "shaped-infusion-402417"
}

provider "google" {
  project = var.project_id
}

# Step 1: Create Custom Role
resource "google_project_iam_custom_role" "custom_role" {
  project     = var.project_id
  role_id     = "custom_storage_get_iam_policy_role"
  title       = "Custom role for storage buckets getIamPolicy"
  description = "Custom role to allow getting IAM policy for storage buckets"
  permissions = ["storage.buckets.getIamPolicy"]
}

# Step 2: Create Service Account
resource "google_service_account" "service_account" {
  account_id   = "my-service-account"
  display_name = "My Service Account"
}

# Step 3: Assign roles to the service account
resource "google_project_iam_member" "viewer_role" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

# Step 4: Assign custom role to the service account
resource "google_project_iam_member" "custom_role_assignment" {
  project = var.project_id
  role    = google_project_iam_custom_role.custom_role.name
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

# Step 5: Generate JSON key for service account and store in Secret Manager
resource "google_service_account_key" "sa_key" {
  service_account_id = google_service_account.service_account.name
}

resource "google_secret_manager_secret" "sa_key_secret" {
  secret_id = "accuknox-sa-key"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "sa_key_version" {
  secret      = google_secret_manager_secret.sa_key_secret.id
  secret_data = base64decode(google_service_account_key.sa_key.private_key)
}

output "service_account_email" {
  value = google_service_account.service_account.email
}

output "secret_name" {
  value       = google_secret_manager_secret.sa_key_secret.name
  description = "Retrieve key via: gcloud secrets versions access latest --secret=accuknox-sa-key"
}
