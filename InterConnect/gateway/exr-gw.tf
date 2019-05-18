# Create a gateway of type ExpressRoute for the given vNet.
# To do
#      confirm the gw sku type
locals {
  name                = "${var.vnet_name}-ERGW"
}

resource "azurerm_public_ip" "ergw-pip" {
    name              = "${local.name}-pip"
    location            = "${var.location}"
    resource_group_name = "${var.resource_group_name}"
    allocation_method   = "Dynamic"
    count = "${var.create_new_gateway}"
}
resource "azurerm_virtual_network_gateway" "vnet-gw" {
  name                = "${local.name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  type                = "ExpressRoute"
  sku                 = "UltraPerformance"

  ip_configuration {
    name                          = "${local.name}-pipconfig"
    public_ip_address_id          = "${azurerm_public_ip.ergw-pip.id}"
    subnet_id                     = "${var.gateway_subnet_id}"
  }

  count = "${var.create_new_gateway}"
}