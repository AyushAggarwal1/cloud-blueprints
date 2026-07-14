# 1. Create Azure AD Application
resource "azuread_application" "app" {
  display_name = var.application_name
}

# 2. Create Service Principal for the app
resource "azuread_service_principal" "sp" {
  client_id = azuread_application.app.client_id
}

# 3. Create Client Secret
resource "azuread_application_password" "secret" {
  application_object_id = azuread_application.app.object_id
}

# 4. Create Custom Role in each subscription
resource "azurerm_role_definition" "custom_role" {
  for_each    = toset(var.subscription_ids)
  name        = "akCloudRole-${each.key}"
  scope       = "/subscriptions/${each.key}"
  description = "Custom Role for CSPM scanning"

  permissions {
    actions = [
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Network/networkSecurityGroups/read",
      "Microsoft.Storage/storageAccounts/read",
      "Microsoft.KeyVault/vaults/read",
      "Microsoft.ContainerService/managedClusters/read",
      "Microsoft.Security/securityContacts/read",
      "Microsoft.Authorization/policyAssignments/read",
      "Microsoft.Authorization/policyDefinitions/read",
      "Microsoft.Resources/tags/read"
    ]
    not_actions = []
  }

  assignable_scopes = [
    "/subscriptions/${each.key}"
  ]
}

# 5. Assign the custom role to the Service Principal in each subscription
resource "azurerm_role_assignment" "assign_custom_role" {
  for_each           = toset(var.subscription_ids)
  principal_id       = azuread_service_principal.sp.object_id
  role_definition_id = azurerm_role_definition.custom_role[each.key].role_definition_resource_id
  scope              = "/subscriptions/${each.key}"
}