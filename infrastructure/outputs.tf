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

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.log.id
}

output "log_analytics_workspace_name" {
  value = azurerm_log_analytics_workspace.log.name
}

output "diagnostic_settings_id" {
  value = azurerm_monitor_diagnostic_setting.aci_diagnostics.id
}

output "action_group_id" {
  value = azurerm_monitor_action_group.alert_group.id
}

output "downtime_alert_id" {
  value = azurerm_monitor_scheduled_query_rules_alert_v2.container_downtime_alert.id
}

output "no_logs_alert_id" {
  value = azurerm_monitor_scheduled_query_rules_alert_v2.no_logs_alert.id
}

output "high_error_rate_alert_id" {
  value = azurerm_monitor_scheduled_query_rules_alert_v2.high_error_rate_alert.id
}

output "auto_heal_function_id" {
  value = azurerm_linux_function_app.auto_heal.id
}

output "auto_heal_function_url" {
  value = "https://${azurerm_linux_function_app.auto_heal.default_hostname}"
}

output "auto_heal_action_group_id" {
  value = azurerm_monitor_action_group.auto_heal_group.id
}

output "auto_heal_alert_id" {
  value = azurerm_monitor_scheduled_query_rules_alert_v2.auto_heal_alert.id
}
