# Setting up Load Balancer
resource "azurerm_public_ip" "jde-load-balancer-public-ip" {
  name                = "PublicIP-${var.lb_name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  allocation_method   = "Static"
  count = "${var.create_public_load_balancer}"
}

# Public Load Balancer setup
resource "azurerm_lb" "jde-public-load-balancer" {
  name                = "${var.lb_name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "${var.lb_name}-frontend-ip-config"
    public_ip_address_id = "${azurerm_public_ip.jde-load-balancer-public-ip.id}"
  }
  count = "${var.create_public_load_balancer}"
}

# Internal Load Balancer Setup
resource "azurerm_lb" "jde-internal-load-balancer" {
  name                = "${var.lb_name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "${var.lb_name}-frontend-ip-config"
    subnet_id            = "${var.frontend_subnet_id}"
    private_ip_address_allocation = "Dynamic"
  }
  count = "${1 - var.create_public_load_balancer}"
}

resource "azurerm_lb_backend_address_pool" "backend-pool" {
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = ["${element(concat(azurerm_lb.jde-public-load-balancer.id, azurerm_lb.jde-internal-load-balancer), 0)}"]
  name                = "BackEndAddressPool-${var.lb_name}"
}
/*resource "azurerm_lb_rule" "jde-lb-rule" {

}*/

//Todo: Setup multiple backend pools for presentation tier and pass the output to "azurerm_network_interface_application_gateway_backend_address_pool_association" resource. 
//Setup Health Probe on each port and setup routing rules on those ports