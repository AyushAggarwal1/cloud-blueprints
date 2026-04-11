provider "google" {
    project = "project-id"
  }
  
  # Step 1: Create Custom Role
  resource "google_project_iam_custom_role" "custom_role" {
    project     = "project-id"
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
    project = "project-id"
    role    = "roles/viewer"
    member  = "serviceAccount:google_service_account.service_account.email"
  }
  # Step 4: Assign custom role to the service account
  resource "google_project_iam_member" "custom_role_assignment" {
    project = "project-id"
    role    = "google_project_iam_custom_role.custom_role.name"
    member  = "serviceAccount:google_service_account.service_account.email"
  }
  # Step 5: Generate JSON key for service account
  resource "null_resource" "save_key_locally" {
    depends_on = [google_service_account.service_account]
    provisioner "local-exec" {
      command = <<EOF
  gcloud iam service-accounts keys create service_account_key.json --iam-account google_service_account.service_account.email --format json
  EOF
    }
  }
  output "key_file_path" {
    value = "service_account_key.json"
  }