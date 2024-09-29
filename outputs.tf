output "resource_group_name" {
  value = azurerm_resource_group.geia_rg.name
}

output "function_app_name" {
  value = azurerm_function_app.geia_functions.name
}

output "web_app_name" {
  value = azurerm_app_service.geia_web_app.name
}

output "sql_server_name" {
  value = azurerm_sql_server.geia_sql_server.name
}

output "key_vault_name" {
  value = azurerm_key_vault.geia_key_vault.name
}