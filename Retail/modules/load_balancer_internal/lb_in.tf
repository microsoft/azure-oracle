# Azure load balancer module

resource "azurerm_lb" "inlb" {
  name                = "${var.prefix}-lb"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"
  tags                = "${var.tags}"
  sku                 = "${var.lb_sku}"

  frontend_ip_configuration {
    name                          = "${var.frontend_name}-app"
    private_ip_address_allocation = "dynamic"
    subnet_id                 = "${var.frontend_subnet_id}"

  }

    frontend_ip_configuration {
    name                          = "${var.frontend_name}-idm"
    private_ip_address_allocation = "dynamic"
    subnet_id                 = "${var.frontend_subnet_id}"

  }

    frontend_ip_configuration {
    name                          = "${var.frontend_name}-integ"
    private_ip_address_allocation = "dynamic"
    subnet_id                 = "${var.frontend_subnet_id}"

  }

    frontend_ip_configuration {
    name                          = "${var.frontend_name}-ria"
    private_ip_address_allocation = "dynamic"
    subnet_id                 = "${var.frontend_subnet_id}"

  }
}

