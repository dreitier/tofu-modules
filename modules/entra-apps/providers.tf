# Credentials from the Azure CLI (az login as an admin with the needed Entra roles) – nothing secret
# passes through OpenTofu
provider "azuread" {
  tenant_id = var.entra_tenant_id
}
