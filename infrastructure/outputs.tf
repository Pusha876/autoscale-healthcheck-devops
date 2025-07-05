output "app_url" {
  value = "http://${azurerm_container_group.app.fqdn}:5000"
}

output "health_check_url" {
  value = "http://${azurerm_container_group.app.fqdn}:5000/health"
}

output "app_fqdn" {
  value = azurerm_container_group.app.fqdn
}

output "resource_group_name" {
  value = data.azurerm_resource_group.rg.name
}
