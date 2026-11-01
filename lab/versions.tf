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

  # Remote state in the bootstrap storage account.
  # Values come from backend.hcl:  terraform init -backend-config=backend.hcl
  backend "azurerm" {
    key              = "lab.tfstate"
    use_azuread_auth = true
  }
}

provider "azurerm" {
  features {
    key_vault {
      # The lab is torn down every session: purge so names never collide
      # and nothing lingers in soft-deleted state.
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      # Let `terraform destroy` remove the RG even if you clicked extra things into it.
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = var.subscription_id
}
