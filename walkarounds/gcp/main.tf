provider "google" {
  project = var.host_project_id
}

# 1. Create Custom Role at Organization Level
resource "google_organization_iam_custom_role" "custom_role" {
  org_id      = var.org_id
  role_id     = "custom_accuknox_cloud_role"
  title       = "Custom Role for AccuKnox (TF)"
  description = "Custom role to allow AccuKnox CSPM scan (Managed by Terraform)"
  
  permissions = [
    "cloudasset.assets.listResource",
    "cloudkms.cryptoKeys.list",
    "cloudkms.keyRings.list",
    "cloudsql.instances.list",
    "cloudsql.users.list",
    "compute.autoscalers.list",
    "compute.backendServices.list",
    "compute.disks.list",
    "compute.firewalls.list",
    "compute.healthChecks.list",
    "compute.instanceGroups.list",
    "compute.instances.getIamPolicy",
    "compute.instances.list",
    "compute.networks.list",
    "compute.projects.get",
    "compute.securityPolicies.list",
    "compute.subnetworks.list",
    "compute.targetHttpProxies.list",
    "container.clusters.list",
    "dns.managedZones.list",
    "iam.roles.list",
    "iam.serviceAccounts.list",
    "resourcemanager.projects.get",
    "resourcemanager.projects.getIamPolicy",
    "serviceusage.services.list",
    "storage.buckets.list",
    "storage.buckets.getIamPolicy"
  ]
}

# 2. Create Service Account in the Host Project
resource "google_service_account" "service_account" {
  account_id   = "accuknox-cloud-sa-tf"
  display_name = "AccuKnox CSPM Service Account (TF)"
  project      = var.host_project_id
}

# 3. Generate Service Account Key
resource "google_service_account_key" "default" {
  service_account_id = google_service_account.service_account.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

# 4. Bind Service Account to Organization (Viewer Role)
resource "google_organization_iam_member" "organization_viewer" {
  org_id = var.org_id
  role   = "roles/viewer"
  member = "serviceAccount:${google_service_account.service_account.email}"
}

# 5. Bind Service Account to Organization (Custom Role)
resource "google_organization_iam_member" "custom_role_assignment" {
  org_id = var.org_id
  role   = google_organization_iam_custom_role.custom_role.id # Dynamic reference
  member = "serviceAccount:${google_service_account.service_account.email}"
}