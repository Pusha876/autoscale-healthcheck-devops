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

# Role assignment for ACR pull with unique name
resource "azurerm_role_assignment" "acr_pull" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.container_identity.principal_id
  
  lifecycle {
    ignore_changes = [role_definition_id]
  }
}

# Random suffix for unique container group names
resource "random_string" "deployment_id" {
  length  = 6
  special = false
  upper   = false
  
  keepers = {
    # Generate new suffix when image tag changes
    image_tag = var.image_tag
  }
}

# Container group with unique naming to avoid conflicts
resource "azurerm_container_group" "app" {
  name                = "${var.app_name}-${random_string.deployment_id.result}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  ip_address_type     = "Public"
  dns_name_label      = "${var.app_name}-${random_string.deployment_id.result}"
  os_type             = "Linux"

  image_registry_credential {
    server   = data.azurerm_container_registry.acr.login_server
    username = data.azurerm_container_registry.acr.admin_username
    password = data.azurerm_container_registry.acr.admin_password
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
    deployment_id = random_string.deployment_id.result
  }

  depends_on = [azurerm_role_assignment.acr_pull]
  
  lifecycle {
    create_before_destroy = true
  }
}
