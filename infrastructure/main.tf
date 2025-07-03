provider "azurerm" {
  features {}
  subscription_id = "b2dd5abd-3642-48b8-929e-2cafb8b4257d"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_container_group" "app" {
  name                = var.app_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_address_type     = "Public"
  dns_name_label      = var.app_name
  os_type             = "Linux"

  container {
    name   = "healthcheck-api"
    image  = "mcr.microsoft.com/azure-functions/python:4-python3.11-appservice"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 5000
      protocol = "TCP"
    }

    commands = [
      "/bin/bash",
      "-c",
      "pip install flask gunicorn flask-cors && python -c \"from flask import Flask, jsonify; import os; app = Flask(__name__); @app.route('/health', methods=['GET']); def health(): return jsonify({'status': 'healthy'}), 200; @app.route('/crash', methods=['GET']); def crash(): os._exit(1)\" > app.py && gunicorn --bind 0.0.0.0:5000 --workers 2 app:app"
    ]

    environment_variables = {
      "FLASK_APP" = "app.py"
    }
  }

  tags = {
    environment = "development"
  }
}
