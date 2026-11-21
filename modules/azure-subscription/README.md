# azure-subscription

Resources in the Azure subscription that predate basement (imported): resource groups, container
registry, storage accounts and the RBAC assignments of people/groups. Cloud Shell storage (csb*) and
Azure-created groups (DefaultResourceGroup-*) are left alone. Service principal credentials and
storage keys are not managed (they would end up in the state).

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_azure_subscription_id"></a> [azure\_subscription\_id](#input\_azure\_subscription\_id) | Subscription (config/globals/azure.tfvars) | `string` | n/a | yes |
| <a name="input_container_registries"></a> [container\_registries](#input\_container\_registries) | Azure Container Registries by name | <pre>map(object({<br/>    import              = optional(bool, true)<br/>    resource_group_name = string<br/>    location            = string<br/>    sku                 = optional(string, "Basic")<br/>    admin_enabled       = optional(bool, false)<br/>    tags                = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_entra_tenant_id"></a> [entra\_tenant\_id](#input\_entra\_tenant\_id) | n/a | `string` | n/a | yes |
| <a name="input_resource_groups"></a> [resource\_groups](#input\_resource\_groups) | Resource groups managed by this unit, by name | <pre>map(object({<br/>    import   = optional(bool, true)<br/>    location = string<br/>    tags     = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments) | Azure RBAC role assignments in the subscription | <pre>list(object({<br/>    scope          = string           # relative to the subscription: "" | resourceGroups/<rg>[/providers/…]<br/>    role           = string           # built-in role name<br/>    principal_type = string           # User | Group<br/>    principal      = string           # user principal name | group display name<br/>    description    = optional(string) # changing it replaces the assignment<br/>    import_id      = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_storage_accounts"></a> [storage\_accounts](#input\_storage\_accounts) | Storage accounts by name | <pre>map(object({<br/>    import                          = optional(bool, true)<br/>    resource_group_name             = string<br/>    location                        = string<br/>    account_tier                    = optional(string, "Standard")<br/>    account_replication_type        = optional(string, "LRS")<br/>    access_tier                     = optional(string, "Hot")<br/>    allow_nested_items_to_be_public = optional(bool, false)<br/>    cross_tenant_replication        = optional(bool, false)<br/>    shared_access_key_enabled       = optional(bool, true)<br/>    min_tls_version                 = optional(string, "TLS1_2")<br/>    # Enabled | Disabled | SecuredByPerimeter – azurerm 5 replaced public_network_access_enabled with it<br/>    public_network_access = optional(string, "Enabled")<br/>    tags                  = optional(map(string), {})<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_container_registry_login_servers"></a> [container\_registry\_login\_servers](#output\_container\_registry\_login\_servers) | n/a |
<!-- END_TF_DOCS -->
