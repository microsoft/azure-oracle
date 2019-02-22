

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.vnet_name}"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"
  address_space       = ["${var.vnet_cidr}"]   #TODO: could be multiples -- flatten/list
}

# TODO: Check if we need any of the gateways
# I think we will need a VNET Gateway. But, that should be a part of the GatewaySubnet, which would be a part of main.network.tf