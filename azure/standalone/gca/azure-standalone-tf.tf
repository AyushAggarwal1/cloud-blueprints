variable "app_display_name" {
  type        = string
  default     = "Azure-Onboarding-App"
  description = "Display name of the Azure AD Application"
}
variable "subscription_id" {
  type        = string
  default     = ""
  description = "Azure Subscription ID. Leave empty to use current subscription"
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.70"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.7"
    }
    random = {
      source  = "hashicorp/random"
    }
    local = {
      source  = "hashicorp/local"
    }
  }
}
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id != "" ? var.subscription_id : null
}
provider "azuread" {}

resource "azuread_application" "accuknox" {
  display_name = var.app_display_name

  required_resource_access {
      resource_app_id = "00000003-0000-0000-c000-000000000000"  # Microsoft Graph
  
      resource_access {
        id   = "5778995a-e1bf-45b8-affa-663a9f3f4d04"  # Directory.Read.All
        type = "Scope"
      }
  }
}

resource "azuread_service_principal" "accuknox_sp" {
  client_id = azuread_application.accuknox.client_id
}
resource "azuread_service_principal_password" "client_secret" {
  service_principal_id = azuread_service_principal.accuknox_sp.id
}
data "azurerm_subscription" "current" {
  subscription_id = var.subscription_id != "" ? var.subscription_id : null
}
data "azurerm_client_config" "current" {}

// resource "azurerm_role_assignment" "reader_role" {
//   scope                = data.azurerm_subscription.current.id
//   role_definition_name = "Reader"
//   principal_id         = azuread_service_principal.accuknox_sp.object_id
// }

resource "azurerm_role_definition" "custom_accuknox_ml_role" {
  name        = "AccuKnox-Scanner-Role"
  scope       = data.azurerm_subscription.current.id
  description = "Custom role for CSPM Scanner for AccuKnox"
  permissions {
    actions = [
"Microsoft.MachineLearningServices/workspaces/onlineEndpoints/score/action",
"Microsoft.Advisor/recommendations/read",
"Microsoft.AlertsManagement/alerts/read",
"Microsoft.ApiManagement/service/apis/read",
"Microsoft.ApiManagement/service/backends/read",
"Microsoft.ApiManagement/service/products/read",
"Microsoft.ApiManagement/service/read",
"Microsoft.AppConfiguration/configurationStores/read",
"Microsoft.AppPlatform/Spring/read",
"Microsoft.Authorization/denyAssignments/read",
"Microsoft.Authorization/locks/read",
"Microsoft.Authorization/roleAssignments/read",
"Microsoft.Authorization/roleDefinitions/read",
"Microsoft.Automation/automationAccounts/read",
"Microsoft.Automation/automationAccounts/runbooks/read",
"Microsoft.Automation/automationAccounts/variables/read",
"Microsoft.Batch/batchAccounts/read",
"Microsoft.Cache/redis/firewallRules/read",
"Microsoft.Cache/redis/linkedServers/read",
"Microsoft.Cache/redis/patchSchedules/read",
"Microsoft.Cache/redis/privateEndpointConnections/read",
"Microsoft.Cache/redis/read",
"Microsoft.CognitiveServices/accounts/deployments/read",
"Microsoft.CognitiveServices/accounts/models/read",
"Microsoft.CognitiveServices/accounts/read",
"Microsoft.Compute/availabilitySets/read",
"Microsoft.Compute/diskAccesses/read",
"Microsoft.Compute/diskEncryptionSets/read",
"Microsoft.Compute/disks/read",
"Microsoft.Compute/galleries/read",
"Microsoft.Compute/locations/vmSizes/read",
"Microsoft.Compute/skus/read",
"Microsoft.Compute/snapshots/read",
"Microsoft.Compute/sshPublicKeys/read",
"Microsoft.Compute/virtualMachineScaleSets/extensions/read",
"Microsoft.Compute/virtualMachineScaleSets/instanceView/read",
"Microsoft.Compute/virtualMachineScaleSets/read",
"Microsoft.Compute/virtualMachineScaleSets/virtualMachines/instanceView/read",
"Microsoft.Compute/virtualMachineScaleSets/virtualMachines/read",
"Microsoft.Compute/virtualMachines/extensions/read",
"Microsoft.Compute/virtualMachines/instanceView/read",
"Microsoft.Compute/virtualMachines/read",
"Microsoft.Consumption/usageDetails/read",
"Microsoft.ContainerInstance/containerGroups/read",
"Microsoft.ContainerRegistry/registries/read",
"Microsoft.ContainerRegistry/registries/replications/read",
"Microsoft.ContainerRegistry/registries/webhooks/read",
"Microsoft.ContainerService/locations/orchestrators/read",
"Microsoft.ContainerService/managedClusters/agentPools/read",
"Microsoft.ContainerService/managedClusters/read",
"Microsoft.ContainerService/managedClusters/upgradeProfiles/read",
"Microsoft.DBforMySQL/flexibleServers/configurations/read",
"Microsoft.DBforMySQL/flexibleServers/firewallRules/read",
"Microsoft.DBforMySQL/flexibleServers/read",
"Microsoft.DBforPostgreSQL/flexibleServers/configurations/read",
"Microsoft.DBforPostgreSQL/flexibleServers/firewallRules/read",
"Microsoft.DBforPostgreSQL/flexibleServers/read",
"Microsoft.DataFactory/factories/datasets/read",
"Microsoft.DataFactory/factories/linkedservices/read",
"Microsoft.DataFactory/factories/pipelines/read",
"Microsoft.DataFactory/factories/privateEndpointConnections/read",
"Microsoft.DataFactory/factories/read",
"Microsoft.DataFactory/factories/triggers/read",
"Microsoft.Databricks/workspaces/read",
"Microsoft.Devices/IotHubs/read",
"Microsoft.EventGrid/domains/read",
"Microsoft.EventGrid/topics/read",
"Microsoft.EventHub/namespaces/authorizationRules/read",
"Microsoft.EventHub/namespaces/eventhubs/read",
"Microsoft.EventHub/namespaces/networkRuleSets/read",
"Microsoft.EventHub/namespaces/read",
"Microsoft.GuestConfiguration/guestConfigurationAssignments/read",
"Microsoft.Insights/actionGroups/read",
"Microsoft.Insights/activityLogAlerts/read",
"Microsoft.Insights/autoscalesettings/read",
"Microsoft.Insights/components/read",
"Microsoft.Insights/metricAlerts/read",
"Microsoft.Insights/metrics/read",
"Microsoft.KeyVault/checkNameAvailability/read",
"Microsoft.KeyVault/locations/deletedVaults/read",
"Microsoft.KeyVault/locations/operationResults/read",
"Microsoft.KeyVault/operations/read",
"Microsoft.KeyVault/vaults/keys/read",
"Microsoft.KeyVault/vaults/read",
"Microsoft.KeyVault/vaults/secrets/read",
"Microsoft.Kusto/clusters/read",
"Microsoft.MachineLearningServices/workspaces/computes/read",
"Microsoft.MachineLearningServices/workspaces/read",
"Microsoft.Maintenance/maintenanceConfigurations/read",
"Microsoft.ManagedServices/registrationAssignments/read",
"Microsoft.ManagedServices/registrationDefinitions/read",
"Microsoft.Network/applicationGatewayWebApplicationFirewallPolicies/read",
"Microsoft.Network/applicationGateways/read",
"Microsoft.Network/applicationSecurityGroups/read",
"Microsoft.Network/azureFirewalls/read",
"Microsoft.Network/bastionHosts/read",
"Microsoft.Network/dnszones/read",
"Microsoft.Network/expressRouteCircuits/read",
"Microsoft.Network/loadBalancers/backendAddressPools/read",
"Microsoft.Network/loadBalancers/frontendIPConfigurations/read",
"Microsoft.Network/loadBalancers/inboundNatRules/read",
"Microsoft.Network/loadBalancers/loadBalancingRules/read",
"Microsoft.Network/loadBalancers/outboundRules/read",
"Microsoft.Network/loadBalancers/probes/read",
"Microsoft.Network/loadBalancers/read",
"Microsoft.Network/locations/serviceTags/read",
"Microsoft.Network/locations/usages/read",
"Microsoft.Network/natGateways/read",
"Microsoft.Network/networkInterfaces/ipConfigurations/read",
"Microsoft.Network/networkInterfaces/read",
"Microsoft.Network/networkProfiles/read",
"Microsoft.Network/networkSecurityGroups/defaultSecurityRules/read",
"Microsoft.Network/networkSecurityGroups/read",
"Microsoft.Network/networkSecurityGroups/securityRules/read",
"Microsoft.Network/networkWatchers/flowLogs/read",
"Microsoft.Network/networkWatchers/read",
"Microsoft.Network/privateDnsZones/read",
"Microsoft.Network/privateDnsZones/virtualNetworkLinks/read",
"Microsoft.Network/privateEndpoints/read",
"Microsoft.Network/publicIPAddresses/read",
"Microsoft.Network/routeTables/read",
"Microsoft.Network/routeTables/routes/read",
"Microsoft.Network/virtualNetworkGateways/read",
"Microsoft.Network/virtualNetworks/read",
"Microsoft.Network/virtualNetworks/subnets/read",
"Microsoft.Network/virtualNetworks/subnets/resourceNavigationLinks/read",
"Microsoft.Network/virtualNetworks/subnets/serviceAssociationLinks/read",
"Microsoft.Network/virtualNetworks/virtualNetworkPeerings/read",
"Microsoft.OperationalInsights/workspaces/read",
"Microsoft.RecoveryServices/vaults/backupPolicies/read",
"Microsoft.RecoveryServices/vaults/backupProtectedItems/read",
"Microsoft.RecoveryServices/vaults/read",
"Microsoft.ResourceGraph/operations/read",
"Microsoft.ResourceGraph/resourceChanges/read",
"Microsoft.ResourceGraph/resources/read",
"Microsoft.ResourceGraph/resourcesHistory/read",
"Microsoft.Resources/deployments/read",
"Microsoft.Resources/links/read",
"Microsoft.Resources/providers/read",
"Microsoft.Resources/resources/read",
"Microsoft.Resources/subscriptions/locations/read",
"Microsoft.Resources/subscriptions/read",
"Microsoft.Resources/subscriptions/resourceGroups/read",
"Microsoft.Resources/subscriptions/resources/read",
"Microsoft.Resources/tenants/read",
"Microsoft.Search/searchServices/read",
"Microsoft.ServiceBus/namespaces/authorizationRules/read",
"Microsoft.ServiceBus/namespaces/privateEndpointConnections/read",
"Microsoft.ServiceBus/namespaces/queues/read",
"Microsoft.ServiceBus/namespaces/read",
"Microsoft.ServiceBus/namespaces/topics/read",
"Microsoft.SignalRService/SignalR/read",
"Microsoft.Sql/managedInstances/read",
"Microsoft.Sql/servers/administrators/read",
"Microsoft.Sql/servers/advancedThreatProtectionSettings/read",
"Microsoft.Sql/servers/auditingSettings/read",
"Microsoft.Sql/servers/connectionPolicies/read",
"Microsoft.Sql/servers/databases/auditingSettings/read",
"Microsoft.Sql/servers/databases/automaticTuning/read",
"Microsoft.Sql/servers/databases/backupShortTermRetentionPolicies/read",
"Microsoft.Sql/servers/databases/currentSensitivityLabels/read",
"Microsoft.Sql/servers/databases/dataMaskingPolicies/read",
"Microsoft.Sql/servers/databases/ledgerDigestUploads/read",
"Microsoft.Sql/servers/databases/read",
"Microsoft.Sql/servers/databases/sensitivityLabels/read",
"Microsoft.Sql/servers/databases/syncGroups/read",
"Microsoft.Sql/servers/databases/transparentDataEncryption/read",
"Microsoft.Sql/servers/databases/vulnerabilityAssessments/read",
"Microsoft.Sql/servers/databases/vulnerabilityAssessments/scans/read",
"Microsoft.Sql/servers/devOpsAuditingSettings/read",
"Microsoft.Sql/servers/elasticPools/read",
"Microsoft.Sql/servers/encryptionProtector/read",
"Microsoft.Sql/servers/failoverGroups/read",
"Microsoft.Sql/servers/firewallRules/read",
"Microsoft.Sql/servers/outboundFirewallRules/read",
"Microsoft.Sql/servers/read",
"Microsoft.Sql/servers/restorableDroppedDatabases/read",
"Microsoft.Sql/servers/securityAlertPolicies/read",
"Microsoft.Sql/servers/virtualNetworkRules/read",
"Microsoft.Sql/servers/vulnerabilityAssessments/read",
"Microsoft.Storage/storageAccounts/blobServices/containers/immutabilityPolicies/read",
"Microsoft.Storage/storageAccounts/blobServices/containers/read",
"Microsoft.Storage/storageAccounts/blobServices/read",
"Microsoft.Storage/storageAccounts/encryptionScopes/read",
"Microsoft.Storage/storageAccounts/fileServices/read",
"Microsoft.Storage/storageAccounts/fileServices/shares/read",
"Microsoft.Storage/storageAccounts/localUsers/read",
"Microsoft.Storage/storageAccounts/managementPolicies/read",
"Microsoft.Storage/storageAccounts/privateEndpointConnections/read",
"Microsoft.Storage/storageAccounts/queueServices/queues/read",
"Microsoft.Storage/storageAccounts/queueServices/read",
"Microsoft.Storage/storageAccounts/read",
"Microsoft.Storage/storageAccounts/tableServices/read",
"Microsoft.Storage/storageAccounts/tableServices/tables/read",
"Microsoft.StorageCache/caches/read",
"Microsoft.StorageSync/storageSyncServices/read",
"Microsoft.StreamAnalytics/streamingjobs/inputs/read",
"Microsoft.StreamAnalytics/streamingjobs/outputs/read",
"Microsoft.StreamAnalytics/streamingjobs/read",
"Microsoft.StreamAnalytics/streamingjobs/transformations/read",
"Microsoft.Web/hostingEnvironments/read",
"Microsoft.Web/serverFarms/read",
"Microsoft.Web/serverFarms/sites/read",
"Microsoft.Web/sites/config/read",
"Microsoft.Web/sites/functions/read",
"Microsoft.Web/sites/read",
"Microsoft.Web/sites/slots/config/read",
"Microsoft.Web/sites/slots/read",
"Microsoft.Web/sites/sourceControls/read",
"Microsoft.Web/sites/virtualNetworkConnections/read"
    ]
  }
  assignable_scopes = [
    data.azurerm_subscription.current.id
  ]
}
resource "azurerm_role_assignment" "custom_ml_role_assignment" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = azurerm_role_definition.custom_accuknox_ml_role.role_definition_resource_id
  principal_id       = azuread_service_principal.accuknox_sp.object_id
}

output "client_id" {
  value = azuread_application.accuknox.client_id
}
output "client_secret" {
  value     = azuread_service_principal_password.client_secret.value
  sensitive = true
}
output "subscription_id" {
  value = split("/", trim(data.azurerm_subscription.current.id, "/"))[1]
}
output "directory_id" {
  value = data.azurerm_client_config.current.tenant_id
}

resource "local_file" "client_secret_and_app_sub_dir_file" {
  filename = "client_secret_and_app_sub_dir.txt"
  content = <<-EOT
Client ID: ${azuread_application.accuknox.client_id}
Client Secret: "${azuread_service_principal_password.client_secret.value}"
Subscription ID: "${split("/", trim(data.azurerm_subscription.current.id, "/"))[1]}"
Directory ID: "${data.azurerm_client_config.current.tenant_id}"
EOT
}
