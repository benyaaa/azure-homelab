# --- Key Vault (RBAC mode, no access policies) --------------------------------

resource "azurerm_key_vault" "lab" {
  name                       = "kv-homelab-${local.suffix}"
  resource_group_name        = azurerm_resource_group.lab.name
  location                   = azurerm_resource_group.lab.location
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # must stay false or the lab can't be purged on destroy
  tags                       = local.tags
}

resource "azurerm_role_assignment" "me_kv_admin" {
  scope                = azurerm_key_vault.lab.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}
