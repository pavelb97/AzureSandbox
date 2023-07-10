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
}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.project}-resource-group"
  location = var.location
}

# FAs require a storage account to host the app container
resource "azurerm_storage_account" "storage_account" {
  name = lower("${var.project}storage")
  resource_group_name = azurerm_resource_group.resource_group.name
  location = var.location
  account_tier = "Standard"
  account_replication_type = "LRS"      # Local Redundant Storage

}

# FAs require a ASP - used to define the scope of resources associated with the FA
resource "azurerm_service_plan" "app_service_plan" {
  name                = "${var.project}-app-service-plan"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  sku_name = "B1"
  os_type = "Linux"
}

resource "azurerm_function_app" "function_app" {
  name                       = "${var.project}-function-app"
  resource_group_name        = azurerm_resource_group.resource_group.name
  location                   = var.location
  
  os_type = "linux"
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key
  version                    = "~3"
  
  app_service_plan_id        = azurerm_service_plan.app_service_plan.id
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python",
    "WEBSITE_RUN_FROM_PACKAGE" = "https://${azurerm_storage_account.storage_account.name}.blob.core.windows.net/${azurerm_storage_container.app_container.name}/${azurerm_storage_blob.storage_blob.name}${data.azurerm_storage_account_blob_container_sas.container_sas.sas}",
    }
  site_config {
        linux_fx_version= "Python|3.8" 
  }
}

# Zip application source code 
data "archive_file" "app_source" {
  type        = "zip"
  source_dir  = "./app"
  output_path = "app.zip"
}

resource "azurerm_storage_container" "app_container" {
  name                  = lower("${var.project}-container")
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "storage_blob" {
  name = "${data.archive_file.app_source.output_path}"
  storage_account_name = azurerm_storage_account.storage_account.name
  storage_container_name = azurerm_storage_container.app_container.name
  type = "Block"
  source = data.archive_file.app_source.output_path
}

# # Shared access signiture - Limits access to blob storage
data "azurerm_storage_account_blob_container_sas" "container_sas" {
  connection_string = azurerm_storage_account.storage_account.primary_connection_string
  container_name    = azurerm_storage_container.app_container.name

  start = "2023-07-09T00:00:00Z"
  expiry = "2023-07-14T00:00:00Z"

  permissions {
    read   = true
    add    = false
    create = false
    write  = false
    delete = false
    list   = false
  }
}