# --- Azure Databricks (optional) ----------------------------------------------
# The workspace itself has ~no standing cost. You pay when clusters/SQL warehouses run.

resource "azurerm_databricks_workspace" "lab" {
  count                       = var.enable_databricks ? 1 : 0
  name                        = "dbw-homelab-${local.suffix}"
  resource_group_name         = azurerm_resource_group.lab.name
  location                    = azurerm_resource_group.lab.location
  sku                         = "premium" # needed for Unity Catalog and RBAC features
  managed_resource_group_name = "rg-homelab-dbw-managed-${local.suffix}"
  tags                        = local.tags

  custom_parameters {
    # COST GUARDRAIL: the provider default (true = secure cluster connectivity on a
    # managed VNet) creates a NAT gateway that bills ~24/7 even with no clusters.
    # false = cluster nodes get public IPs, no NAT gateway. Fine for a personal lab;
    # in production you'd use VNet injection + private networking instead.
    no_public_ip = false
  }
}

# Unity Catalog access connector: a managed identity Databricks uses to reach the lake.
# Use it in Weekend 4 to create a storage credential + external locations.
resource "azurerm_databricks_access_connector" "uc" {
  count               = var.enable_databricks ? 1 : 0
  name                = "dbac-homelab-${local.suffix}"
  resource_group_name = azurerm_resource_group.lab.name
  location            = azurerm_resource_group.lab.location
  tags                = local.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "uc_lake" {
  count                = var.enable_databricks ? 1 : 0
  scope                = azurerm_storage_account.lake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.uc[0].identity[0].principal_id
}

# ADF managed identity → run Databricks jobs via an MSI linked service (Weekend 5)
resource "azurerm_role_assignment" "adf_dbw" {
  count                = var.enable_databricks ? 1 : 0
  scope                = azurerm_databricks_workspace.lab[0].id
  role_definition_name = "Contributor"
  principal_id         = azurerm_data_factory.lab.identity[0].principal_id
}
