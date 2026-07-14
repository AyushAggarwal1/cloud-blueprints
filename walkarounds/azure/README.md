# AccuKnox CSPM Onboarding for Microsoft Azure

This project uses Terraform to quickly and automatically set up the necessary Azure permissions and onboard your Azure subscriptions to the AccuKnox Cloud Security Posture Management (CSPM) platform.

## What This Module Does

- **Azure Setup**: Creates a secure Read-Only Azure Application and Service Principal.
- **Permissions**: Assigns a custom, read-only CSPM security role to the Application across your target subscriptions.
- **Onboarding**: Calls the CSPM API to register your subscriptions for scanning.

---

## Prerequisites

Before getting started, ensure you have:

- **Terraform**: Installed locally (version >= 1.1.0).
- **Azure CLI**: Installed and authenticated with your Azure account.
- **Azure Subscription IDs**: A list of subscriptions you want to onboard for scanning.
- **AccuKnox CSPM API Token**: A valid bearer token for API authentication.
- **Permissions**: Owner or User Access Administrator role on target Azure subscriptions.

---

## Quick Start Guide (5 Simple Steps)

### Step 1: Install & Login

Ensure Terraform is installed and you are logged into Azure via the Azure CLI:

```sh
# Log in to Azure (required for Terraform to work)
az login
```

---

### Step 2: Configure Your Variables

Create a configuration file named `terraform.tfvars` and add your specific details. You can copy the example file:

```sh
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and replace placeholder values with your own:

```hcl
# --- Your CSPM Credentials and Target Subscriptions ---

# Your Azure Subscription IDs (the list of accounts you want to scan)
subscription_ids = [
  "YOUR-FIRST-SUBSCRIPTION-ID",
  "YOUR-SECOND-SUBSCRIPTION-ID"
]

# Your AccuKnox CSPM Bearer Token
cspm_token = "YOUR-SECURE-API-TOKEN-HERE"

# --- Optional Customization ---

# Name for the Azure Application that will be created
application_name = "ak-azure-onboard-application"

# CSPM Label/Tag names for filtering in the AccuKnox console
label_name = "azure-prod-scanner"
tag_value  = "production-tag"
```

---

### Step 3: Initialize Terraform

Run the initialization command to download necessary providers (azurerm, azuread, and terracurl):

```sh
terraform init
```

---

### Step 4: Check the Plan

Always review what Terraform is going to create or change before applying:

```sh
terraform plan
```

---

### Step 5: Deploy and Onboard

Execute the deployment. This will create the Azure resources and make API calls to AccuKnox CSPM to start the scanning process:

```sh
terraform apply
```

> **Note**: Type `yes` when prompted to confirm the changes.

---

## Key Outputs

After a successful `terraform apply`, Terraform will display credentials needed to verify the integration in the CSPM console:

| Output Name              | Description                                                   |
|--------------------------|---------------------------------------------------------------|
| `application_client_id`  | The Client ID of the new Azure AD Application                |
| `tenant_id`              | Your Azure Tenant ID                                          |
| `generated_label_id`     | The ID of the Label created in the CSPM platform            |
| `onboarded_subscriptions`| List of Azure Subscription IDs targeted for onboarding       |

---

## Module Structure

| File                     | Description                                                 |
|--------------------------|-------------------------------------------------------------|
| `main.tf`                | Core Azure resources: Application, Service Principal, role bindings |
| `cspm.tf`                | Terracurl resources for CSPM API calls                      |
| `variables.tf`           | Input variables for Azure configuration and CSPM metadata   |
| `outputs.tf`             | Output definitions                                          |
| `versions.tf`            | Terraform and provider version constraints                  |
| `terraform.tfvars.example` | Example input variables configuration file                  |

---

## Security Considerations

- Keep your `terraform.tfvars` file secure and do not commit it to version control.
- Use Azure Key Vault or environment variables to manage sensitive credentials like `cspm_token`.
- The created Azure Application has read-only permissions for security scanning purposes only.
- Regularly audit and rotate API tokens in the AccuKnox CSPM console.

---

## Troubleshooting

**Error: "AADSTS700016: Application with identifier not found in the directory"**  
Ensure you are logged into the correct Azure tenant via `az login`.

**Error: "Insufficient privileges to complete the operation"**  
Verify that your Azure account has Owner or User Access Administrator role on the target subscriptions.

**Error: "CSPM API token is invalid or expired"**  
Regenerate a new API token from the AccuKnox CSPM console and update `terraform.tfvars`.

---

## Additional Resources

For more information about AccuKnox CSPM and Azure integration, refer to the official AccuKnox documentation.

---
