#-------------------------------
# Local Declarations
#-------------------------------
locals {
  account_tier             = (var.account_kind == "FileStorage" ? "Premium" : split("_", var.skuname)[0])
  account_replication_type = (local.account_tier == "Premium" ? "LRS" : split("_", var.skuname)[1])
}

#-----------------------------------------------------------
# Resource Group Creation or selection - Default is "true"
#-----------------------------------------------------------
data "azurerm_resource_group" "rgrp" {
  count = var.create_resource_group == false ? 1 : 0
  name  = var.resource_group_name
}

resource "azurerm_resource_group" "rg" {
  count    = var.create_resource_group ? 1 : 0
  name     = lower(var.resource_group_name)
  location = var.location
  tags     = merge({ "ResourceName" = format("%s", var.resource_group_name) }, var.tags)
}

#---------------------------------------
# Storage Account Creation or selection
#---------------------------------------
resource "random_string" "unique" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "storeacc" {
  depends_on = [
    azurerm_resource_group.rg
  ]
  name                      = substr(format("sta%s%s", lower(replace(var.storage_account_name, "/[[:^alnum:]]/", "")), random_string.unique.result), 0, 24)
  resource_group_name       = var.resource_group_name
  location                  = var.location
  account_kind              = var.account_kind
  account_tier              = local.account_tier
  account_replication_type  = local.account_replication_type
  enable_https_traffic_only = true
  min_tls_version           = var.min_tls_version
  allow_blob_public_access  = var.enable_advanced_threat_protection == true ? true : false
  tags                      = merge({ "ResourceName" = substr(format("sta%s%s", lower(replace(var.storage_account_name, "/[[:^alnum:]]/", "")), random_string.unique.result), 0, 24) }, var.tags, )

  identity {
    type = var.assign_identity ? "SystemAssigned" : null
  }

  blob_properties {
    delete_retention_policy {
      days = var.soft_delete_retention
    }
  }

  dynamic "network_rules" {
    for_each = var.network_rules != null ? ["true"] : []
    content {
      default_action             = "Deny"
      bypass                     = var.network_rules.bypass
      ip_rules                   = var.network_rules.ip_rules
      virtual_network_subnet_ids = var.network_rules.subnet_ids
    }
  }
}

#------------------------------------
# Storage Advanced Threat Protection 
#------------------------------------
resource "azurerm_advanced_threat_protection" "atp" {
  target_resource_id = azurerm_storage_account.storeacc.id
  enabled            = var.enable_advanced_threat_protection
}

#-------------------------------
# Storage Container Creation
#-------------------------------
resource "azurerm_storage_container" "container" {
  depends_on = [
    azurerm_storage_account.storeacc
  ]
  count                 = length(var.containers_list)
  name                  = var.containers_list[count.index].name
  storage_account_name  = azurerm_storage_account.storeacc.name
  container_access_type = var.containers_list[count.index].access_type
}

#----------------------
# Application Insights
#----------------------
resource "azurerm_application_insights" "fa" {
  depends_on = [
    azurerm_resource_group.rg
  ]
  name                = var.application_insights_name
  location            = var.location
  resource_group_name = lower(var.resource_group_name)
  application_type    = "other"
}

#--------------------------
# Create app service plan
#--------------------------
resource "azurerm_app_service_plan" "asp_fa" {
  depends_on = [
    azurerm_resource_group.rg
  ]
  name                = var.app_service_plan_name
  resource_group_name = lower(var.resource_group_name)
  location            = var.location
  kind                = var.tier == "Dynamic" && var.size == "Y1" ? "FunctionApp" : "Windows"

  sku {
    tier = var.tier
    size = var.size
  }
}

#---------------------
# Create function app
#---------------------
resource "azurerm_function_app" "fa" {
  depends_on = [
    azurerm_app_service_plan.asp_fa, azurerm_storage_container.container
  ]
  name                       = var.function_app_name
  resource_group_name        = var.resource_group_name
  location                   = var.location
  app_service_plan_id        = azurerm_app_service_plan.asp_fa.id
  storage_account_name       = azurerm_storage_account.storeacc.name
  storage_account_access_key = azurerm_storage_account.storeacc.primary_access_key
  version                    = var.runtime_version
  https_only                 = true

  app_settings = {
    FUNCTIONS_EXTENSION_VERSION    = "~3"
    FUNCTIONS_WORKER_RUNTIME       = "dotnet"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.fa.instrumentation_key
  }

  site_config {
    always_on = false
    cors {
      allowed_origins = var.cors_allowed_origins
    }
  }
}

#-----------------------------
# Deploy code to function app
#-----------------------------
resource "null_resource" "deploy_function" {
  depends_on = [
    azurerm_function_app.fa
  ]
  provisioner "local-exec" {
    command = join("", ["az functionapp deployment source config --ids ", azurerm_function_app.fa.id, " --repo-url https://github.com/arun-mittal/azure-generate-thumbnail-blob-upload-trigger", " --branch master --manual-integration"])
  }
}
