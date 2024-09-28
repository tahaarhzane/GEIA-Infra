# Configure the Azure provider
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
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

# Variables
variable "location" {
  default = "East US"
}

variable "project_name" {
  default = "geia"
}

variable "environment" {
  default = "dev"
}

# Resource Group
resource "azurerm_resource_group" "geia_rg" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
}

# Storage Account
resource "azurerm_storage_account" "geia_storage" {
  name                     = "${var.project_name}${var.environment}sa"
  resource_group_name      = azurerm_resource_group.geia_rg.name
  location                 = azurerm_resource_group.geia_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
  }
}

# Blob Containers
resource "azurerm_storage_container" "raw_data" {
  name                  = "raw-data"
  storage_account_name  = azurerm_storage_account.geia_storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "processed_data" {
  name                  = "processed-data"
  storage_account_name  = azurerm_storage_account.geia_storage.name
  container_access_type = "private"
}

# Application Insights
resource "azurerm_application_insights" "geia_appinsights" {
  name                = "${var.project_name}-${var.environment}-appinsights"
  location            = azurerm_resource_group.geia_rg.location
  resource_group_name = azurerm_resource_group.geia_rg.name
  application_type    = "web"
}

# Function App (Consumption Plan)
resource "azurerm_app_service_plan" "geia_app_plan" {
  name                = "${var.project_name}-${var.environment}-app-plan"
  location            = azurerm_resource_group.geia_rg.location
  resource_group_name = azurerm_resource_group.geia_rg.name
  kind                = "FunctionApp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "geia_function" {
  name                       = "${var.project_name}-${var.environment}-function"
  location                   = azurerm_resource_group.geia_rg.location
  resource_group_name        = azurerm_resource_group.geia_rg.name
  app_service_plan_id        = azurerm_app_service_plan.geia_app_plan.id
  storage_account_name       = azurerm_storage_account.geia_storage.name
  storage_account_access_key = azurerm_storage_account.geia_storage.primary_access_key
  os_type                    = "linux"
  version                    = "~4"

  site_config {
    dotnet_framework_version = "v6.0"
    use_32_bit_worker_process = false
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME       = "dotnet"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.geia_appinsights.instrumentation_key
  }

  identity {
    type = "SystemAssigned"
  }
}

# SQL Server
resource "azurerm_mssql_server" "geia_sqlserver" {
  name                         = "${var.project_name}-${var.environment}-sqlserver"
  resource_group_name          = azurerm_resource_group.geia_rg.name
  location                     = azurerm_resource_group.geia_rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "ChangeMe123!" # Change this in a real scenario
  minimum_tls_version          = "1.2"

  azuread_administrator {
    login_username = "SQL Admin"
    object_id      = azuread_group.sql_admins.object_id
  }
}

# SQL Database
resource "azurerm_mssql_database" "geia_sqldb" {
  name           = "${var.project_name}-${var.environment}-sqldb"
  server_id      = azurerm_mssql_server.geia_sqlserver.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  sku_name       = "S0"

  short_term_retention_policy {
    retention_days = 7
  }
}

# Cosmos DB
resource "azurerm_cosmosdb_account" "geia_cosmos" {
  name                = "${var.project_name}-${var.environment}-cosmos"
  location            = azurerm_resource_group.geia_rg.location
  resource_group_name = azurerm_resource_group.geia_rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  enable_automatic_failover = true

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }
}

# App Service Plan (Premium V2 tier for better performance)
resource "azurerm_app_service_plan" "geia_web_plan" {
  name                = "${var.project_name}-${var.environment}-web-plan"
  location            = azurerm_resource_group.geia_rg.location
  resource_group_name = azurerm_resource_group.geia_rg.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "PremiumV2"
    size = "P1v2"
  }
}

# App Service
resource "azurerm_app_service" "geia_webapp" {
  name                = "${var.project_name}-${var.environment}-webapp"
  location            = azurerm_resource_group.geia_rg.location
  resource_group_name = azurerm_resource_group.geia_rg.name
  app_service_plan_id = azurerm_app_service_plan.geia_web_plan.id

  site_config {
    linux_fx_version = "DOTNETCORE|6.0"
    always_on        = true
    http2_enabled    = true
  }

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.geia_appinsights.instrumentation_key
  }

  identity {
    type = "SystemAssigned"
  }
}

# Key Vault
resource "azurerm_key_vault" "geia_keyvault" {
  name                       = "${var.project_name}-${var.environment}-kv"
  location                   = azurerm_resource_group.geia_rg.location
  resource_group_name        = azurerm_resource_group.geia_rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
}

# Grant Key Vault access to Function App
resource "azurerm_key_vault_access_policy" "function_app_policy" {
  key_vault_id = azurerm_key_vault.geia_keyvault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_function_app.geia_function.identity[0].principal_id

  secret_permissions = [
    "Get", "List"
  ]
}

# Virtual Network
resource "azurerm_virtual_network" "geia_vnet" {
  name                = "${var.project_name}-${var.environment}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.geia_rg.location
  resource_group_name = azurerm_resource_group.geia_rg.name
}

# Subnets
resource "azurerm_subnet" "function_subnet" {
  name                 = "function-subnet"
  resource_group_name  = azurerm_resource_group.geia_rg.name
  virtual_network_name = azurerm_virtual_network.geia_vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "function-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "webapp_subnet" {
  name                 = "webapp-subnet"
  resource_group_name  = azurerm_resource_group.geia_rg.name
  virtual_network_name = azurerm_virtual_network.geia_vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "webapp-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Azure AD Group for SQL Admins
resource "azuread_group" "sql_admins" {
  display_name     = "GEIA SQL Admins"
  security_enabled = true
}

# Outputs
output "function_app_name" {
  value = azurerm_function_app.geia_function.name
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.geia_sqlserver.fully_qualified_domain_name
}

output "webapp_url" {
  value = "https://${azurerm_app_service.geia_webapp.default_site_hostname}"
}

output "cosmos_db_endpoint" {
  value = azurerm_cosmosdb_account.geia_cosmos.endpoint
}

output "key_vault_uri" {
  value = azurerm_key_vault.geia_keyvault.vault_uri
}