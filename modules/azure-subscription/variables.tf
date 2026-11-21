variable "entra_tenant_id" {
  type = string
}

variable "azure_subscription_id" {
  type        = string
  description = "Subscription (config/globals/azure.tfvars)"
}

variable "resource_groups" {
  type = map(object({
    import   = optional(bool, true)
    location = string
    tags     = optional(map(string), {})
  }))
  default     = {}
  description = "Resource groups managed by this unit, by name"
}

variable "container_registries" {
  type = map(object({
    import              = optional(bool, true)
    resource_group_name = string
    location            = string
    sku                 = optional(string, "Basic")
    admin_enabled       = optional(bool, false)
    tags                = optional(map(string), {})
  }))
  default     = {}
  description = "Azure Container Registries by name"
}

variable "storage_accounts" {
  type = map(object({
    import                          = optional(bool, true)
    resource_group_name             = string
    location                        = string
    account_tier                    = optional(string, "Standard")
    account_replication_type        = optional(string, "LRS")
    access_tier                     = optional(string, "Hot")
    allow_nested_items_to_be_public = optional(bool, false)
    cross_tenant_replication        = optional(bool, false)
    shared_access_key_enabled       = optional(bool, true)
    min_tls_version                 = optional(string, "TLS1_2")
    # Enabled | Disabled | SecuredByPerimeter – azurerm 5 replaced public_network_access_enabled with it
    public_network_access = optional(string, "Enabled")
    tags                  = optional(map(string), {})
  }))
  default     = {}
  description = "Storage accounts by name"
}

variable "role_assignments" {
  type = list(object({
    scope          = string           # relative to the subscription: "" | resourceGroups/<rg>[/providers/…]
    role           = string           # built-in role name
    principal_type = string           # User | Group
    principal      = string           # user principal name | group display name
    description    = optional(string) # changing it replaces the assignment
    import_id      = optional(string)
  }))
  default     = []
  description = "Azure RBAC role assignments in the subscription"
}
