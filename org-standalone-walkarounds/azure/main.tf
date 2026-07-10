terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    terracurl = {
      source  = "devops-rob/terracurl"
      version = "1.2.1"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
  
  # This tells Terraform NOT to try registering all Azure providers at startup.
  # This prevents the "ConflictingConcurrentWriteNotAllowed" (409) errors.
  skip_provider_registration = true
  
  subscription_id = var.subscription_ids[0]
}

provider "azuread" {}

provider "terracurl" {}

data "azurerm_client_config" "current" {}