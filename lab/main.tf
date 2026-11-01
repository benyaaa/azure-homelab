# -----------------------------------------------------------------------------
# LAB — disposable. Everything lives in ONE resource group: destroy = clean slate.
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

locals {
  suffix = random_string.suffix.result
  tags = {
    project    = "homelab"
    layer      = "lab"
    owner      = var.owner
    disposable = "true"
  }
}

resource "azurerm_resource_group" "lab" {
  name     = "rg-homelab-lab"
  location = var.location
  tags     = local.tags
}

# --- ADLS Gen2 data lake ------------------------------------------------------

resource "azurerm_storage_account" "lake" {
  name                            = "sthomelablake${local.suffix}"
  resource_group_name             = azurerm_resource_group.lab.name
  location                        = azurerm_resource_group.lab.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS" # cheapest; fine for a lab
  is_hns_enabled                  = true  # hierarchical namespace = ADLS Gen2
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false # force identity-based access (good habit)
  tags                            = local.tags
}

# Containers on an HNS account are ADLS Gen2 filesystems.
# Created via the management plane, so no data-plane role is needed for Terraform.
resource "azurerm_storage_container" "lake" {
  for_each              = toset(var.lake_containers)
  name                  = each.value
  storage_account_id    = azurerm_storage_account.lake.id
  container_access_type = "private"
}

# You (the signed-in user) can read/write the lake from the portal, CLI and Storage Explorer.
resource "azurerm_role_assignment" "me_lake" {
  scope                = azurerm_storage_account.lake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}
