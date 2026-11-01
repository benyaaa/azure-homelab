# -----------------------------------------------------------------------------
# BOOTSTRAP — run once, keep forever.
# Guardrails (budget + policy) and remote state storage. Costs: ~€0.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  # Bootstrap keeps LOCAL state on purpose (chicken-and-egg with the state storage).
  # Back up bootstrap/terraform.tfstate somewhere private, or simply re-import if lost.
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

locals {
  tags = {
    project = "homelab"
    layer   = "core"
    owner   = var.owner
  }
}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

# --- Core resource group (persistent) ----------------------------------------

resource "azurerm_resource_group" "core" {
  name     = "rg-homelab-core"
  location = var.location
  tags     = local.tags
}

# --- Terraform remote state ---------------------------------------------------

resource "azurerm_storage_account" "tfstate" {
  name                            = "sthomelabtf${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.core.name
  location                        = azurerm_resource_group.core.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = local.tags

  blob_properties {
    versioning_enabled = true # lets you recover a corrupted state file
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

# --- Guardrail 1: monthly budget with email alerts ---------------------------

resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = "budget-homelab-monthly"
  subscription_id = "/subscriptions/${var.subscription_id}"
  amount          = var.monthly_budget
  time_grain      = "Monthly"

  time_period {
    start_date = var.budget_start_date # must be the 1st of a month
  }

  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = [var.alert_email]
  }

  # Early warning: fires when Azure FORECASTS you'll exceed the budget this month.
  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Forecasted"
    contact_emails = [var.alert_email]
  }

  lifecycle {
    ignore_changes = [time_period]
  }
}

# --- Guardrail 2: Azure Policy (actually PREVENTS expensive mistakes) ---------

data "azurerm_policy_definition" "allowed_locations" {
  display_name = "Allowed locations"
}

data "azurerm_policy_definition" "allowed_vm_skus" {
  display_name = "Allowed virtual machine size SKUs"
}

resource "azurerm_subscription_policy_assignment" "allowed_locations" {
  name                 = "homelab-allowed-locations"
  display_name         = "Home lab: allowed regions only"
  subscription_id      = "/subscriptions/${var.subscription_id}"
  policy_definition_id = data.azurerm_policy_definition.allowed_locations.id

  parameters = jsonencode({
    listOfAllowedLocations = { value = var.allowed_locations }
  })
}

# Databricks clusters are Azure VMs, so this also caps cluster node sizes.
resource "azurerm_subscription_policy_assignment" "allowed_vm_skus" {
  name                 = "homelab-allowed-vm-skus"
  display_name         = "Home lab: small VM sizes only"
  subscription_id      = "/subscriptions/${var.subscription_id}"
  policy_definition_id = data.azurerm_policy_definition.allowed_vm_skus.id

  parameters = jsonencode({
    listOfAllowedSKUs = { value = var.allowed_vm_skus }
  })
}

# --- Outputs: copy these into lab/backend.hcl ---------------------------------

output "backend_resource_group_name" {
  value = azurerm_resource_group.core.name
}

output "backend_storage_account_name" {
  value = azurerm_storage_account.tfstate.name
}

output "backend_container_name" {
  value = azurerm_storage_container.tfstate.name
}
