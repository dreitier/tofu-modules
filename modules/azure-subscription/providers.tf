# Credentials from the Azure CLI (az login) – nothing secret passes through OpenTofu
provider "azurerm" {
  tenant_id       = var.entra_tenant_id
  subscription_id = var.azure_subscription_id
  # Resource providers are registered by hand where needed – no automatic registration on every plan
  resource_provider_registrations = "none"

  features {}
}

provider "azuread" {
  tenant_id = var.entra_tenant_id
}
