# AccuKnox CSPM Onboarding for Google Cloud Platform (GCP)

This Terraform module automates the required infrastructure setup and API integrations to onboard multiple GCP projects into the AccuKnox Cloud Security Posture Management (CSPM) solution.

## Features

- **GCP Setup**: 
  - Creates a custom Organization-Level IAM Role with the required read-only permissions for security scanning.
  - Creates a Service Account in a designated host project.
  - Binds this Service Account to the custom IAM role across the organization.
- **CSPM API Integration**: 
  - Uses the [terracurl provider](https://registry.terraform.io/providers/devops-rob/terracurl/latest/docs) to create necessary Labels and Tags within AccuKnox CSPM.
- **Project Onboarding**: 
  - Onboards your specified target GCP Project IDs to the CSPM platform via API calls using the generated Service Account credentials.

---

## Prerequisites

Before using this module, you must have:

- **GCP Organization Admin Role**: Permissions to create Custom Organization IAM Roles and bindings.
- **Terraform**: Installed locally (version >= 1.1.0).
- **AccuKnox CSPM API Token**: Valid bearer token for authenticating with the AccuKnox CSPM API.
- **Target Details**: GCP Organization ID and a list of target Project IDs for onboarding.

---

## Quick Start

### 1. Initialize and Configure

Copy the example variables file and fill in your environment details:

```sh
cp terraform.tfvars.example terraform.tfvars
```

Then, edit `terraform.tfvars` with your data:

```hcl
# GCP Organization and Host Project
org_id          = "YOUR_GCP_ORGANIZATION_ID"     # e.g., '00000000000'
host_project_id = "your-service-account-host-project"  # Project for Service Account

# List of Target Projects
target_project_ids = [
  "project-a",
  "project-b",
  "project-c"
]

# AccuKnox CSPM Credentials (keep secure!)
cspm_token = "YOUR_CSPM_BEARER_TOKEN"

# CSPM Metadata
label_name = "gcp-prod-label"
aws_prefix = "gcp-prod"
tag_value  = "production-tag"
```

---

### 2. Install Providers

Initialize Terraform and install dependencies:

```sh
terraform init
```

---

### 3. Plan and Apply

Review proposed infrastructure changes:

```sh
terraform plan
```

If the plan looks correct, apply to execute onboarding:

```sh
terraform apply
```

---

## Outputs

| Output Name            | Description                                                 |
|------------------------|------------------------------------------------------------|
| `service_account_email`| Email address of Service Account created                   |
| `cspm_label_id`        | ID of the Label created in the CSPM platform               |
| `cspm_tag_id`          | ID of the Tag created in the CSPM platform                 |
| `onboarded_projects`   | List of targeted GCP Project IDs for onboarding            |

---

## Module Structure

| File                  | Description                                               |
|-----------------------|----------------------------------------------------------|
| `main.tf`             | Core GCP resources: IAM role, Service Account, bindings  |
| `cspm.tf`             | Terracurl resources for CSPM API calls                   |
| `variables.tf`        | Input variables for GCP configuration and CSPM metadata  |
| `outputs.tf`          | Output definitions                                       |
| `versions.tf`         | Terraform and provider version constraints               |
| `terraform.tfvars.example` | Example input variables configuration file       |

---

## Notes

- Ensure required GCP APIs are enabled: Compute Engine API, IAM API, Cloud Resource Manager API, Cloud Functions API, KMS API, Kubernetes API, and Cloud SQL Admin API.
- The module leverages organization-level permissions; consult your cloud admin before use.

---