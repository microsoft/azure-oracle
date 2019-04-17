
locals {
  backend_address_pool_name      = "${var.vnet_name}-bepool"
  frontend_port_name             = "${var.vnet_name}-feport"
  frontend_ip_configuration_name = "${var.vnet_name}-feip"
  http_setting_name              = "httpset-${var.vnet_name}"
  listener_name                  = "${var.vnet_name}-listener"
  request_routing_rule_name      = "rrule-${var.vnet_name}"
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

  frontend_ip_configuration {
    name                 = "${local.frontend_ip_configuration_name}"
    public_ip_address_id = "${azurerm_public_ip.app_gw.id}"
  }

  frontend_port {
    name = "${local.frontend_port_name}-1"
    port = 80
  }

  backend_address_pool {
    name = "app-${local.backend_address_pool_name}"
    ip_addresses = ["${var.lb_frontend_ips[0]}"]
  }
  backend_address_pool {
    name = "idm-${local.backend_address_pool_name}"
    ip_addresses = ["${var.lb_frontend_ips[1]}"]
  }
  backend_address_pool {
    name = "integ-${local.backend_address_pool_name}"
    ip_addresses = ["${var.lb_frontend_ips[2]}"]
  }
  backend_address_pool {
    name = "ria-${local.backend_address_pool_name}"
    ip_addresses = ["${var.lb_frontend_ips[3]}"]
  }

  backend_http_settings {
    name                  = "8001-${local.http_setting_name}"
    cookie_based_affinity = "Disabled"
    port                  = 8001
    protocol              = "Http"
    request_timeout       = 1
  }

  backend_http_settings {
    name                  = "8003-${local.http_setting_name}"
    cookie_based_affinity = "Disabled"
    port                  = 8003
    protocol              = "Http"
    request_timeout       = 1
  }

  backend_http_settings {
    name                  = "8005-${local.http_setting_name}"
    cookie_based_affinity = "Disabled"
    port                  = 8005
    protocol              = "Http"
    request_timeout       = 1
  }

  backend_http_settings {
    name                  = "8007-${local.http_setting_name}"
    cookie_based_affinity = "Disabled"
    port                  = 8007
    protocol              = "Http"
    request_timeout       = 1
  }
  
 backend_http_settings {
    name                  = "8019-${local.http_setting_name}"
    cookie_based_affinity = "Disabled"
    port                  = 8019
    protocol              = "Http"
    request_timeout       = 1
  }
  
 backend_http_settings {
    name                  = "14000-${local.http_setting_name}"
    cookie_based_affinity = "Disabled"
    port                  = 14000
    protocol              = "Http"
    request_timeout       = 1
  }
  backend_http_settings {
    name                  = "14100-${local.http_setting_name}"
    cookie_based_affinity = "Disabled"
    port                  = 14100
    protocol              = "Http"
    request_timeout       = 1
  }
  backend_http_settings {
    name                  = "rib-${local.http_setting_name}"
    cookie_based_affinity = "Disabled"
    port                  = 8001 #need to be range 8001-8015
    protocol              = "Http"
    request_timeout       = 1
  }

  backend_http_settings {
    name                  = "8100-${local.http_setting_name}"
    cookie_based_affinity = "Disabled"
    port                  = 8100 #need to be range 8100-8105
    protocol              = "Http"
    request_timeout       = 1
  }

 backend_http_settings {
    name                  = "8200-${local.http_setting_name}"
    cookie_based_affinity = "Disabled"
    port                  = 8200 #need to be range 8200-8205
    protocol              = "Http"
    request_timeout       = 1
  }
  backend_http_settings {
    name                  = "${local.http_setting_name}-bipub"
    cookie_based_affinity = "Disabled"
    port                  = 8001
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
    url_path_map_name          = "retail"
  }

    url_path_map {
     name    = "retail"
     default_backend_address_pool_name  = "app-${local.backend_address_pool_name}"
     default_backend_http_settings_name = "14000-${local.http_setting_name}"
    
          path_rule {
            name = "OIM"
            paths = ["/identity"]
            backend_address_pool_name = "idm-${local.backend_address_pool_name}"
            backend_http_settings_name = "14000-${local.http_setting_name}"
  }
          path_rule {
            name = "OAM"
            paths = ["/oam"]
            backend_address_pool_name = "idm-${local.backend_address_pool_name}"
            backend_http_settings_name = "14100-${local.http_setting_name}"
  }    
          path_rule {
            name = "RMS"
            paths = ["/rms"]
            backend_address_pool_name = "app-${local.backend_address_pool_name}"
            backend_http_settings_name = "8001-${local.http_setting_name}"
  }
          path_rule {
            name = "Alloc"
            paths = ["/alloc"]
            backend_address_pool_name = "app-${local.backend_address_pool_name}"
            backend_http_settings_name = "8003-${local.http_setting_name}"
  }
           path_rule {
            name = "reim"
            paths = ["/reim"]
            backend_address_pool_name = "app-${local.backend_address_pool_name}"
            backend_http_settings_name = "8005-${local.http_setting_name}"
  }
          path_rule {
            name = "resa"
            paths = ["/resa"]
            backend_address_pool_name = "app-${local.backend_address_pool_name}"
            backend_http_settings_name = "8007-${local.http_setting_name}"
  }
           path_rule {
            name = "rpm"
            paths = ["/rpm"]
            backend_address_pool_name = "app-${local.backend_address_pool_name}"
            backend_http_settings_name = "8019-${local.http_setting_name}"
  }
          path_rule {
            name = "rib"
            paths = ["/rib*"]
            backend_address_pool_name = "integ-${local.backend_address_pool_name}"
            backend_http_settings_name = "8001-${local.http_setting_name}"
  }
          path_rule {
            name = "rsb"
            paths = ["/rsb*"]
            backend_address_pool_name = "integ-${local.backend_address_pool_name}"
            backend_http_settings_name = "8100-${local.http_setting_name}"
  }
           path_rule {
            name = "bdi"
            paths = ["/bdi*"]
            backend_address_pool_name = "integ-${local.backend_address_pool_name}"
            backend_http_settings_name = "8200-${local.http_setting_name}"
  }

          path_rule {
            name = "xmlpserver"
            paths = ["/xmlpserver"]
            backend_address_pool_name = "ria-${local.backend_address_pool_name}"
            backend_http_settings_name = "8001-${local.http_setting_name}"
  }

    }
  }


     

