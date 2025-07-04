provider "azurerm" {
  features {}
  subscription_id = "b2dd5abd-3642-48b8-929e-2cafb8b4257d"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

data "azurerm_container_registry" "acr" {
  name                = "autoscalehealthcheckacr"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_user_assigned_identity" "container_identity" {
  location            = azurerm_resource_group.rg.location
  name                = "container-identity"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.container_identity.principal_id
}

data "azurerm_client_config" "current" {}

resource "azurerm_container_group" "app" {
  name                = var.app_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Public"
  dns_name_label      = var.app_name
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
  }

  depends_on = [azurerm_role_assignment.acr_pull]
}
