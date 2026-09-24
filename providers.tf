terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  # Access is scoped to a single resource group (Contributor via PIM),
  # so Terraform must NOT try to register resource providers at the
  # subscription level — that would fail with AuthorizationFailed.
  skip_provider_registration = true
}

data "azurerm_resource_group" "sandbox" {
  name = var.resource_group_name
}
