# --- Azure Data Factory -------------------------------------------------------
# Infra lives here. Pipelines are better authored in the ADF Studio with Git
# integration (see the weekend plan): that's how most teams work with ADF.

resource "azurerm_data_factory" "lab" {
  name                   = "adf-homelab-${local.suffix}"
  resource_group_name    = azurerm_resource_group.lab.name
  location               = azurerm_resource_group.lab.location
  public_network_enabled = true
  tags                   = local.tags

  identity {
    type = "SystemAssigned"
  }
}

# ADF managed identity → read/write the lake
resource "azurerm_role_assignment" "adf_lake" {
  scope                = azurerm_storage_account.lake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.lab.identity[0].principal_id
}

# ADF managed identity → read secrets
resource "azurerm_role_assignment" "adf_kv" {
  scope                = azurerm_key_vault.lab.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_data_factory.lab.identity[0].principal_id
}

# Linked services using managed identity (no keys anywhere)
resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "lake" {
  name                 = "ls_adls_lake"
  data_factory_id      = azurerm_data_factory.lab.id
  url                  = azurerm_storage_account.lake.primary_dfs_endpoint
  use_managed_identity = true

  depends_on = [azurerm_role_assignment.adf_lake]
}

resource "azurerm_data_factory_linked_service_key_vault" "kv" {
  name            = "ls_key_vault"
  data_factory_id = azurerm_data_factory.lab.id
  key_vault_id    = azurerm_key_vault.lab.id

  depends_on = [azurerm_role_assignment.adf_kv]
}
