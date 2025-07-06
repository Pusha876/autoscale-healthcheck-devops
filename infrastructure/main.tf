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
