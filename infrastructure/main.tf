provider "azurerm" {
  features {}
  subscription_id = "b2dd5abd-3642-48b8-929e-2cafb8b4257d"
}

# Use existing resource group
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# Use existing ACR
data "azurerm_container_registry" "acr" {
  name                = "autoscalehealthcheckacr"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "log" {
  name                = "autoscale-law"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Create user-assigned identity with import support
resource "azurerm_user_assigned_identity" "container_identity" {
  location            = data.azurerm_resource_group.rg.location
  name                = "container-identity"
  resource_group_name = data.azurerm_resource_group.rg.name
  
  lifecycle {
    # Prevent recreation if it already exists
    prevent_destroy = false
    ignore_changes = [
      tags
    ]
  }
}

# Random suffix for unique container group names (only when not using existing)
resource "random_string" "deployment_id" {
  count   = var.use_existing_identity ? 0 : 1
  length  = 6
  special = false
  upper   = false
  
  keepers = {
    # Generate new suffix when image tag changes
    image_tag = var.image_tag
  }
}

# Container group with conditional naming
resource "azurerm_container_group" "app" {
  name                = var.use_existing_identity ? var.app_name : "${var.app_name}-${random_string.deployment_id[0].result}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  ip_address_type     = "Public"
  dns_name_label      = var.use_existing_identity ? var.app_name : "${var.app_name}-${random_string.deployment_id[0].result}"
  os_type             = "Linux"

  # Use admin credentials for ACR authentication (simpler, no role permissions needed)
  image_registry_credential {
    server   = data.azurerm_container_registry.acr.login_server
    username = data.azurerm_container_registry.acr.admin_username
    password = data.azurerm_container_registry.acr.admin_password
  }

  # Optional: Use managed identity if enabled and role assignment exists
  dynamic "identity" {
    for_each = var.enable_managed_identity_auth ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = [azurerm_user_assigned_identity.container_identity.id]
    }
  }

  container {
    name   = "healthcheck-api"
    image  = "${data.azurerm_container_registry.acr.login_server}/healthcheck-api:${var.image_tag}"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 5000
      protocol = "TCP"
    }

    environment_variables = {
      "FLASK_APP" = "app.py"
    }
  }

  tags = {
    environment = "development"
    managed_by  = "terraform"
    build_id    = var.image_tag
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Diagnostic settings for Container Instance
resource "azurerm_monitor_diagnostic_setting" "aci_diagnostics" {
  name               = "aci-diagnostics"
  target_resource_id = azurerm_container_group.app.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log.id

  enabled_log {
    category = "ContainerInstanceLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Action Group for alert notifications
resource "azurerm_monitor_action_group" "alert_group" {
  name                = "healthcheck-alerts"
  resource_group_name = data.azurerm_resource_group.rg.name
  short_name          = "hc-alerts"

  email_receiver {
    name          = "admin"
    email_address = "djpusha@gmail.com"  # TODO: Replace with your actual email
  }

  # Optional: Add webhook for integration with external systems
  # webhook_receiver {
  #   name        = "webhook"
  #   service_uri = "https://your-webhook-url.com"
  # }
}

# Alert Rule for Container Downtime Detection
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "container_downtime_alert" {
  name                = "container-downtime-alert"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  
  evaluation_frequency = "PT5M"  # Every 5 minutes
  window_duration      = "PT10M" # Look back 10 minutes
  scopes               = [azurerm_log_analytics_workspace.log.id]
  severity             = 2       # High severity
  
  criteria {
    query = <<-QUERY
      ContainerLog
      | where TimeGenerated > ago(10m)
      | where LogEntry contains "Traceback" or LogEntry contains "error" or LogEntry contains "ERROR"
    QUERY
    
    time_aggregation_method = "Count"
    threshold               = 1
    operator                = "GreaterThan"
  }
  
  action {
    action_groups = [azurerm_monitor_action_group.alert_group.id]
  }
  
  description = "Alert when container errors are detected in the health check API"
  enabled     = true
  
  tags = {
    environment = "development"
    managed_by  = "terraform"
  }
}

# Alert Rule for No Logs Received (Potential Downtime)
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "no_logs_alert" {
  name                = "no-logs-alert"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  
  evaluation_frequency = "PT5M"  # Every 5 minutes
  window_duration      = "PT15M" # Look back 15 minutes
  scopes               = [azurerm_log_analytics_workspace.log.id]
  severity             = 1       # Critical severity
  
  criteria {
    query = <<-QUERY
      ContainerLog
      | where TimeGenerated > ago(15m)
    QUERY
    
    time_aggregation_method = "Count"
    threshold               = 1
    operator                = "LessThan"
  }
  
  action {
    action_groups = [azurerm_monitor_action_group.alert_group.id]
  }
  
  description = "Alert when no logs are received from the health check API (potential downtime)"
  enabled     = true
  
  tags = {
    environment = "development"
    managed_by  = "terraform"
  }
}

# Alert Rule for High Error Rate
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "high_error_rate_alert" {
  name                = "high-error-rate-alert"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  
  evaluation_frequency = "PT5M"  # Every 5 minutes
  window_duration      = "PT30M" # Look back 30 minutes
  scopes               = [azurerm_log_analytics_workspace.log.id]
  severity             = 2       # High severity
  
  criteria {
    query = <<-QUERY
      ContainerLog
      | where TimeGenerated > ago(30m)
      | where LogEntry contains "HTTP"
      | extend StatusCode = extract(@"(\d{3})", 1, LogEntry)
      | extend StatusCodeInt = toint(StatusCode)
      | summarize 
          TotalRequests = count(),
          ErrorRequests = countif(StatusCodeInt >= 400)
      | extend ErrorRate = (ErrorRequests * 100.0) / TotalRequests
      | where TotalRequests > 0
      | project ErrorRate
    QUERY
    
    time_aggregation_method = "Average"
    threshold               = 10.0  # 10% error rate
    operator                = "GreaterThan"
    
    metric_measure_column = "ErrorRate"
  }
  
  action {
    action_groups = [azurerm_monitor_action_group.alert_group.id]
  }
  
  description = "Alert when HTTP error rate exceeds 10% over 30 minutes"
  enabled     = true
  
  tags = {
    environment = "development"
    managed_by  = "terraform"
  }
}

# Storage Account for Azure Function
resource "azurerm_storage_account" "function_storage" {
  name                     = "autoheal${random_string.storage_suffix.result}"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  tags = {
    environment = "development"
    managed_by  = "terraform"
    purpose     = "auto-heal-function"
  }
}

# Random suffix for storage account name
resource "random_string" "storage_suffix" {
  length  = 10
  special = false
  upper   = false
  numeric = true
}

# App Service Plan for Azure Function
resource "azurerm_service_plan" "function_plan" {
  name                = "autoscale-heal-plan"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "Y1"  # Consumption plan
  
  tags = {
    environment = "development"
    managed_by  = "terraform"
  }
}

# Azure Function App for Auto-Healing
resource "azurerm_linux_function_app" "auto_heal" {
  name                = "autoscale-heal-func"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  
  storage_account_name       = azurerm_storage_account.function_storage.name
  storage_account_access_key = azurerm_storage_account.function_storage.primary_access_key
  service_plan_id            = azurerm_service_plan.function_plan.id
  
  site_config {
    application_stack {
      python_version = "3.11"
    }
  }
  
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"     = "python"
    "AzureWebJobsFeatureFlags"     = "EnableWorkerIndexing"
    "AZURE_SUBSCRIPTION_ID"        = "b2dd5abd-3642-48b8-929e-2cafb8b4257d"
    "RESOURCE_GROUP_NAME"          = data.azurerm_resource_group.rg.name
    "CONTAINER_GROUP_NAME"         = azurerm_container_group.app.name
    "HEALTH_CHECK_URL"             = "http://${azurerm_container_group.app.fqdn}:5000/health"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
  }
  
  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.container_identity.id]
  }
  
  tags = {
    environment = "development"
    managed_by  = "terraform"
    purpose     = "auto-heal"
  }
}

# Role assignment for Function to restart container groups
resource "azurerm_role_assignment" "function_container_restart" {
  scope                = data.azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.container_identity.principal_id
}

# Action Group for Auto-Heal (webhook to Function)
resource "azurerm_monitor_action_group" "auto_heal_group" {
  name                = "auto-heal-alerts"
  resource_group_name = data.azurerm_resource_group.rg.name
  short_name          = "heal-alert"

  azure_function_receiver {
    name                     = "auto-heal-function"
    function_app_resource_id = azurerm_linux_function_app.auto_heal.id
    function_name            = "auto_heal_trigger"
    http_trigger_url         = "https://${azurerm_linux_function_app.auto_heal.default_hostname}/api/auto_heal_trigger"
    use_common_alert_schema  = true
  }
  
  tags = {
    environment = "development"
    managed_by  = "terraform"
  }
}

# Enhanced Alert Rule with Auto-Heal Action
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "auto_heal_alert" {
  name                = "auto-heal-trigger-alert"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  
  evaluation_frequency = "PT5M"  # Every 5 minutes
  window_duration      = "PT10M" # Look back 10 minutes
  scopes               = [azurerm_log_analytics_workspace.log.id]
  severity             = 1       # Critical severity
  
  criteria {
    query = <<-QUERY
      ContainerLog
      | where TimeGenerated > ago(10m)
      | where LogEntry contains "Traceback" or LogEntry contains "ERROR" or LogEntry contains "500"
    QUERY
    
    time_aggregation_method = "Count"
    threshold               = 3  # 3 or more errors trigger auto-heal
    operator                = "GreaterThanOrEqual"
  }
  
  action {
    action_groups = [
      azurerm_monitor_action_group.alert_group.id,      # Email notification
      azurerm_monitor_action_group.auto_heal_group.id   # Auto-heal trigger
    ]
  }
  
  description = "Auto-heal alert: Triggers container restart when critical errors are detected"
  enabled     = true
  
  tags = {
    environment = "development"
    managed_by  = "terraform"
    purpose     = "auto-heal"
  }
}
