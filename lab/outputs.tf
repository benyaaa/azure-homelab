output "resource_group" {
  value = azurerm_resource_group.lab.name
}

output "lake_account_name" {
  value = azurerm_storage_account.lake.name
}

output "lake_dfs_endpoint" {
  value = azurerm_storage_account.lake.primary_dfs_endpoint
}

output "key_vault_uri" {
  value = azurerm_key_vault.lab.vault_uri
}

output "data_factory_name" {
  value = azurerm_data_factory.lab.name
}

output "databricks_workspace_url" {
  value = var.enable_databricks ? "https://${azurerm_databricks_workspace.lab[0].workspace_url}" : null
}

output "uc_access_connector_id" {
  description = "Use when creating the Unity Catalog storage credential."
  value       = var.enable_databricks ? azurerm_databricks_access_connector.uc[0].id : null
}
