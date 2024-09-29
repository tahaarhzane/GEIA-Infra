# GEIA-Infra
Global Environmental Impact Analyzer Infrastructure as Code with Terraform

## Overview
This repository contains Terraform configurations for deploying the Global Environmental Impact Analyzer (GEIA) infrastructure on Microsoft Azure. The infrastructure is designed to be cost-effective, utilizing free tier resources where possible.

## Resources Created
- Azure Functions (Consumption plan)
- Azure Blob Storage
- Azure SQL Database (Basic tier)
- Azure App Service (Free F1 tier)
- Azure Monitor (Application Insights)
- Azure Key Vault

## Cost Management
This infrastructure is designed to stay within Azure's free tier limits. A budget alert is set up to notify you if costs are approaching $1.

## Usage
1. Install Terraform
2. Clone this repository
3. Run `terraform init` to initialize Terraform
4. Set up your Azure credentials
5. Run `terraform plan` to see the changes that will be made
6. Run `terraform apply` to create the infrastructure

## Variables
Make sure to set the following variables:
- `sql_admin_password`: A secure password for the SQL Server admin
- `alert_email`: Your email address for budget alerts

## Note
Remember that free tier resources have limitations and may not be suitable for production workloads. Always monitor your usage and adjust as necessary.





# GEIA Infrastructure as Code: A Detailed Explanation

## 1. Provider Configuration

```hcl
provider "azurerm" {
  features {}
}
```

This block configures the Azure Resource Manager (AzureRM) provider for Terraform. It tells Terraform that we'll be working with Azure resources. The empty `features {}` block is required for the AzureRM provider version 2.0 and above.

## 2. Resource Group

```hcl
resource "azurerm_resource_group" "geia_rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}
```

This creates an Azure Resource Group, which is a logical container for resources deployed on Azure. The name is constructed using a prefix (defined in variables) and "-rg". The location is also specified via a variable.

## 3. Azure Functions

### Storage Account for Functions
```hcl
resource "azurerm_storage_account" "geia_func_storage" {
  name                     = "${lower(var.prefix)}func${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.geia_rg.name
  location                 = azurerm_resource_group.geia_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Cool"
}
```

This creates a Storage Account required for Azure Functions. The name is constructed using the prefix, "func", and a random string to ensure uniqueness. It's set to use the Standard tier with Locally Redundant Storage (LRS) and Cool access tier for cost optimization.

### App Service Plan for Functions
```hcl
resource "azurerm_app_service_plan" "geia_func_plan" {
  name                = "${var.prefix}-func-plan"
  location            = azurerm_resource_group.geia_rg.location
  resource_group_name = azurerm_resource_group.geia_rg.name
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}
```

This creates an App Service Plan for the Azure Functions. It's set to "Dynamic" tier and "Y1" size, which corresponds to the Consumption plan (pay-per-execution model).

### Function App
```hcl
resource "azurerm_function_app" "geia_functions" {
  name                       = "${var.prefix}-functions-${random_string.random.result}"
  location                   = azurerm_resource_group.geia_rg.location
  resource_group_name        = azurerm_resource_group.geia_rg.name
  app_service_plan_id        = azurerm_app_service_plan.geia_func_plan.id
  storage_account_name       = azurerm_storage_account.geia_func_storage.name
  storage_account_access_key = azurerm_storage_account.geia_func_storage.primary_access_key
}
```

This creates the actual Function App, linking it to the App Service Plan and Storage Account created earlier.

## 4. Azure Blob Storage

```hcl
resource "azurerm_storage_account" "geia_blob_storage" {
  name                     = "${lower(var.prefix)}blob${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.geia_rg.name
  location                 = azurerm_resource_group.geia_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Cool"
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
```

This section creates a Storage Account for blob storage and two containers within it: "raw-data" and "processed-data". The Storage Account uses the Standard tier with LRS and Cool access tier. Both containers are set to private access.

## 5. Azure SQL Database

```hcl
resource "azurerm_sql_server" "geia_sql_server" {
  name                         = "${var.prefix}-sql-server-${random_string.random.result}"
  resource_group_name          = azurerm_resource_group.geia_rg.name
  location                     = azurerm_resource_group.geia_rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = azurerm_key_vault_secret.sql_admin_password.value
}

resource "azurerm_sql_database" "geia_sql_db" {
  name                = "${var.prefix}-sql-db"
  resource_group_name = azurerm_resource_group.geia_rg.name
  location            = azurerm_resource_group.geia_rg.location
  server_name         = azurerm_sql_server.geia_sql_server.name
  edition             = "Basic"
  requested_service_objective_name = "Basic"
}
```

This creates an Azure SQL Server and a Basic tier SQL Database. The server name includes a random string for uniqueness. The admin password is retrieved from Azure Key Vault for security.

## 6. Azure App Service

```hcl
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
}

resource "azurerm_app_service" "geia_web_app" {
  name                = "${var.prefix}-web-app-${random_string.random.result}"
  location            = azurerm_resource_group.geia_rg.location
  resource_group_name = azurerm_resource_group.geia_rg.name
  app_service_plan_id = azurerm_app_service_plan.geia_app_plan.id

  site_config {
    linux_fx_version = "PYTHON|3.8"
  }
}
```

This creates an App Service Plan and an App Service (web app) using the Free F1 tier. The web app is configured to use Python 3.8.

## 7. Azure Monitor (Application Insights)

```hcl
resource "azurerm_application_insights" "geia_app_insights" {
  name                = "${var.prefix}-app-insights"
  location            = azurerm_resource_group.geia_rg.location
  resource_group_name = azurerm_resource_group.geia_rg.name
  application_type    = "web"
}
```

This sets up Application Insights for monitoring the web application.

## 8. Azure Key Vault

```hcl
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
}

resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = var.sql_admin_password
  key_vault_id = azurerm_key_vault.geia_key_vault.id
}
```

This creates an Azure Key Vault for securely storing secrets, and adds the SQL admin password as a secret.

## 9. Budget Alert

```hcl
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
```

This sets up a budget alert that will notify you if the resource group's costs approach $1, helping to ensure you stay within the free tier limits.

## 10. Variables and Outputs

The `variables.tf` file defines input variables that can be customized when applying the Terraform configuration. The `outputs.tf` file defines values that will be displayed after the Terraform apply is complete, providing easy access to important resource information.

## How It All Works Together

1. When you run `terraform apply`, Terraform reads these configuration files.
2. It first sets up the resource group as a container for all other resources.
3. Then it creates the storage accounts, SQL server and database, Function App, and App Service, all within this resource group.
4. The Key Vault is created to store sensitive information like the SQL admin password.
5. Application Insights is set up for monitoring.
6. Finally, a budget alert is configured to help manage costs.

All these resources are interconnected. For example, the Function App uses the storage account, the SQL Database is linked to the SQL Server, and the budget alert monitors the entire resource group.

This Infrastructure as Code approach allows you to version control your infrastructure, easily replicate it, and manage it alongside your application code. It provides a consistent and repeatable way to deploy your entire environment.

