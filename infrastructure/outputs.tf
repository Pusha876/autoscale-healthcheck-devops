output "app_url" {
  value = "http://${azurerm_container_group.app.fqdn}:5000"
}

output "app_fqdn" {
  value = azurerm_container_group.app.fqdn
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}
