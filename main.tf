terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id            = "a4e59050-bf58-4a23-941a-974fafd931ad"
  skip_provider_registration = true     # Prevents School & Personal credential clashing
}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.project}-resource-group"
  location = var.location
}

# FAs require a storage account to host the app container
resource "azurerm_storage_account" "storage_account" {
  name = "${var.project}-storage"
  resource_group_name = azurerm_resource_group.resource_group.name
  location = var.location
  account_tier = "Standard"
  account_replication_type = "LRS"      # Local Redundant Storage
}

# FAs require a ASP - used to define the scope of resources associated with the FA
resource "azurerm_app_service_plan" "app_service_plan" {
  name                = "${var.project}-app-service-plan"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  kind                = "FunctionApp"
  reserved = true                       # Must be set to true for linux
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}