# main.tf

# Configure the Azure provider
provider "azurerm" {
  features {}
  version = "~> 2.0"
}

# Create a resource group
resource "azurerm_resource_group" "geia_rg" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags = {
    environment = "development"
    project     = "GEIA"
  }
}

# Create Azure Functions App (Consumption plan)
resource "azurerm_storage_account" "geia_func_storage" {
  name                     = "${lower(var.prefix)}func${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.geia_rg.name
  location                 = azurerm_resource_group.geia_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Cool"
  tags = {
    environment = "development"
    project     = "GEIA"
  }
}

resource "azurerm_app_service_plan" "geia_func_plan" {
  name                = "${var.prefix}-func-plan"
  location            = azurerm_resource_group.geia_rg.location
  resource_group_name = azurerm_resource_group.geia_rg.name
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
  tags = {
    environment = "development"
    project     = "GEIA"
  }
}

resource "azurerm_function_app" "geia_functions" {
  name                       = "${var.prefix}-functions-${random_string.random.result}"
  location                   = azurerm_resource_group.geia_rg.location
  resource_group_name        = azurerm_resource_group.geia_rg.name
  app_service_plan_id        = azurerm_app_service_plan.geia_func_plan.id
  storage_account_name       = azurerm_storage_account.geia_func_storage.name
  storage_account_access_key = azurerm_storage_account.geia_func_storage.primary_access_key
  version                    = "~4"
  tags = {
    environment = "development"
    project     = "GEIA"
  }
}

# Create Azure Blob Storage
resource "azurerm_storage_account" "geia_blob_storage" {
  name                     = "${lower(var.prefix)}blob${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.geia_rg.name
  location                 = azurerm_resource_group.geia_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Cool"
  tags = {
    environment = "development"
    project     = "GEIA"
  }
}

resource "azurerm_storage_container" "raw_data" {
  name                  = "raw-data"
  storage_account_name  = azurerm_storage_account.geia_blob_storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "processed_data" {
  name                  = "processed-data"
  storage_account_name  = azurerm_storage_account.geia_blob_storage.name
  container_access_type = "private"
}

# Create Azure SQL Database
resource "azurerm_sql_server" "geia_sql_server" {
  name                         = "${var.prefix}-sql-server-${random_string.random.result}"
  resource_group_name          = azurerm_resource_group.geia_rg.name
  location                     = azurerm_resource_group.geia_rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = random_password.sql_admin_password.result
  tags = {
    environment = "development"
    project     = "GEIA"
  }
}

resource "azurerm_sql_database" "geia_sql_db" {
  name                = "${var.prefix}-sql-db"
  resource_group_name = azurerm_resource_group.geia_rg.name
  location            = azurerm_resource_group.geia_rg.location
  server_name         = azurerm_sql_server.geia_sql_server.name
  edition             = "Basic"
  tags = {
    environment = "development"
    project     = "GEIA"
  }
}

# Create Azure App Service (Free F1 tier)
resource "azurerm_app_service_plan" "geia_app_plan" {
  name                = "${var.prefix}-app-plan"
  location            = azurerm_resource_group.geia_rg.location
  resource_group_name = azurerm_resource_group.geia_rg.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Free"
    size = "F1"
  }
  tags = {
    environment = "development"
    project     = "GEIA"
  }
}

resource "azurerm_app_service" "geia_web_app" {
  name                = "${var.prefix}-web-app-${random_string.random.result}"
  location            = azurerm_resource_group.geia_rg.location
  resource_group_name = azurerm_resource_group.geia_rg.name
  app_service_plan_id = azurerm_app_service_plan.geia_app_plan.id

  site_config {
    linux_fx_version = "PYTHON|3.8"
  }
  tags = {
    environment = "development"
    project     = "GEIA"
  }
}

# Configure Azure Monitor (Basic, included free)
resource "azurerm_application_insights" "geia_app_insights" {
  name                = "${var.prefix}-app-insights"
  location            = azurerm_resource_group.geia_rg.location
  resource_group_name = azurerm_resource_group.geia_rg.name
  application_type    = "web"
  tags = {
    environment = "development"
    project     = "GEIA"
  }
}


// random password for sql server
resource "random_password" "sql_admin_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Add Azure Key Vault
resource "azurerm_key_vault" "geia_key_vault" {
  name                        = "${var.prefix}-kv-${random_string.random.result}"
  location                    = azurerm_resource_group.geia_rg.location
  resource_group_name         = azurerm_resource_group.geia_rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get", "List", "Create", "Delete", "Update",
    ]

    secret_permissions = [
      "Get", "List", "Set", "Delete",
    ]
  }
  tags = {
    environment = "development"
    project     = "GEIA"
  }
}

# Create a secret for SQL Server admin password
resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = random_password.sql_admin_password.result
  key_vault_id = azurerm_key_vault.geia_key_vault.id
}

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Generate a random string for unique naming
resource "random_string" "random" {
  length  = 8
  special = false
  upper   = false
}

# Add budget alert
resource "azurerm_monitor_action_group" "budget_alert" {
  name                = "budget-alert-action-group"
  resource_group_name = azurerm_resource_group.geia_rg.name
  short_name          = "budget-alert"

  email_receiver {
    name          = "sendtoadmin"
    email_address = var.alert_email
  }
}

resource "azurerm_consumption_budget_resource_group" "budget" {
  name              = "budget"
  resource_group_id = azurerm_resource_group.geia_rg.id

  amount     = 1  # Set to $1 to get alerted if you exceed free tier
  time_grain = "Monthly"
  time_period {
    start_date = "2023-06-01T00:00:00Z"  # Adjust this date
  }

  notification {
    enabled        = true
    threshold      = 90.0
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"

    contact_emails = [
      var.alert_email,
    ]

    contact_groups = [
      azurerm_monitor_action_group.budget_alert.id,
    ]
  }
}