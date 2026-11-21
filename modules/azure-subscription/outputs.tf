output "container_registry_login_servers" {
  value = { for k, r in azurerm_container_registry.this : k => r.login_server }
}
