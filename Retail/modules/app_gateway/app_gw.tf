
locals {
  backend_address_pool_name      = "${var.vnet_name}-bepool"
  frontend_port_name             = "${var.vnet_name}-feport"
  frontend_ip_configuration_name = "${var.vnet_name}-feip"
  http_setting_name              = "${var.vnet_name}-be-htset"
  listener_name                  = "${var.vnet_name}-httplstn"
  request_routing_rule_name      = "${var.vnet_name}-rrule"
}

resource "azurerm_public_ip" "app_gw" {
  name                = "retail_agw-pip"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  allocation_method   = "Dynamic"
}

resource "azurerm_application_gateway" "app_gw" {
  name                = "${var.prefix}-app_gw"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = "${var.frontend_subnet_id}"
  }

  frontend_port {
    name = "${local.frontend_port_name}-1"
    port = 80
  }

    frontend_port {
    name = "${local.frontend_port_name}-2"
    port = 81
  }
    frontend_port {
    name = "${local.frontend_port_name}-3"
    port = 82
  }
    frontend_port {
    name = "${local.frontend_port_name}-4"
    port = 83
  }

  frontend_ip_configuration {
    name                 = "${local.frontend_ip_configuration_name}"
    public_ip_address_id = "${azurerm_public_ip.app_gw.id}"
  }

  backend_address_pool {
    name = "${local.backend_address_pool_name}-1"

  }
  backend_address_pool {
    name = "${local.backend_address_pool_name}-2"

  }
  backend_address_pool {
    name = "${local.backend_address_pool_name}-3"

  }
  backend_address_pool {
    name = "${local.backend_address_pool_name}-4"

  }

  backend_http_settings {
    name                  = "${local.http_setting_name}-1"
    cookie_based_affinity = "Disabled"
    path         = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

    backend_http_settings {
    name                  = "${local.http_setting_name}-2"
    cookie_based_affinity = "Disabled"
    path         = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

    backend_http_settings {
    name                  = "${local.http_setting_name}-3"
    cookie_based_affinity = "Disabled"
    path         = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

    backend_http_settings {
    name                  = "${local.http_setting_name}-4"
    cookie_based_affinity = "Disabled"
    path         = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = "${local.listener_name}-1"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
    frontend_port_name             = "${local.frontend_port_name}-1"
    protocol                       = "Http"
  }

  http_listener {
    name                           = "${local.listener_name}-2"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
    frontend_port_name             = "${local.frontend_port_name}-2"
    protocol                       = "Http"
  }
    http_listener {
    name                           = "${local.listener_name}-3"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
    frontend_port_name             = "${local.frontend_port_name}-3"
    protocol                       = "Http"
  }
    http_listener {
    name                           = "${local.listener_name}-4"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
    frontend_port_name             = "${local.frontend_port_name}-4"
    protocol                       = "Http"
  }
  request_routing_rule {
    name                       = "${local.request_routing_rule_name}-1"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}-1"
    backend_address_pool_name  = "${local.backend_address_pool_name}-1"
    backend_http_settings_name = "${local.http_setting_name}-1"
  }

  
  request_routing_rule {
    name                       = "${local.request_routing_rule_name}-2"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}-2"
    backend_address_pool_name  = "${local.backend_address_pool_name}-2"
    backend_http_settings_name = "${local.http_setting_name}-2"
  }

  
  request_routing_rule {
    name                       = "${local.request_routing_rule_name}-3"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}-3"
    backend_address_pool_name  = "${local.backend_address_pool_name}-3"
    backend_http_settings_name = "${local.http_setting_name}-3"
  }

  
  request_routing_rule {
    name                       = "${local.request_routing_rule_name}-4"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}-4"
    backend_address_pool_name  = "${local.backend_address_pool_name}-4"
    backend_http_settings_name = "${local.http_setting_name}-4"
  }
}