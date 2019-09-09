
locals {
  backend_address_pool_name      = "${var.vnet_name}-bepool"
  frontend_port_name             = "${var.vnet_name}-feport"
  frontend_ip_configuration_name = "${var.vnet_name}-feip"
  http_setting_name              = "httpset-${var.vnet_name}"
  listener_name                  = "${var.vnet_name}-listener"
  request_routing_rule_name      = "rrule-${var.vnet_name}"
}

resource "azurerm_public_ip" "app_gw" {
  name                = "ps_agw-pip"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  allocation_method   = "Static"
  sku = "Standard"
}

resource "azurerm_application_gateway" "app_gw" {
  name                = "${var.prefix}-app_gw"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "ps-gateway-ip-configuration"
    subnet_id = "${var.frontend_subnet_id}"
  }

  frontend_ip_configuration {
    name                 = "${local.frontend_ip_configuration_name}"
    public_ip_address_id = "${azurerm_public_ip.app_gw.id}"
  }

  frontend_port {
    name = "${local.frontend_port_name}-1"
    port = 8000
  }

  backend_address_pool {
    name = "app-${local.backend_address_pool_name}"
    ip_addresses = ["${var.lb_frontend_ips[0]}"]
  }


  backend_http_settings {
    name                  = "8000-${local.http_setting_name}"
    cookie_based_affinity = "Disabled"
    port                  = 8000
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = "${local.listener_name}-1"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
    frontend_port_name             = "${local.frontend_port_name}-1"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name}-1"
    rule_type                  = "PathBasedRouting"
    http_listener_name         = "${local.listener_name}-1"
    url_path_map_name          = "peoplesoft"
  }

    url_path_map {
     name    = "peoplesoft"
     default_backend_address_pool_name  = "app-${local.backend_address_pool_name}"
     default_backend_http_settings_name = "8000-${local.http_setting_name}"
    
          path_rule {
            name = "webserver"
            paths = ["/identity"]
            backend_address_pool_name = "app-${local.backend_address_pool_name}"
            backend_http_settings_name = "8000-${local.http_setting_name}"
  }
          
    }
  }


     

