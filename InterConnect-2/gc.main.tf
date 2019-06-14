resource "azurerm_resource_group" "er_rg" {
  name = "${var.resource_group_name}"
  location = "${var.deployment_location}"
}

# Check if a VNET exists
data "azurerm_virtual_network" "primary_vnet" {
  name = "${var.vnet_name}"
  resource_group_name = "${azurerm_resource_group.er_rg.name}"
  count = "${var.vnet_cidr == "0" ? 1 : 0}"
}

# Create a virtual network within the resource group (no DNS Servers)
resource "azurerm_virtual_network" "primary_vnet" {
  name                = "${var.vnet_name}"
  resource_group_name = "${azurerm_resource_group.er_rg.name}"
  location            = "${var.deployment_location}"
  address_space       = ["${var.vnet_cidr}"]
  count = "${var.vnet_cidr != "0" ? 1 : 0}"
}

# Check if the GatewaySubnet exists. If not, create one
data "azurerm_subnet" "gateway_subnet" {
  name = "GatewaySubnet"
  resource_group_name = "${azurerm_resource_group.er_rg.name}"
  virtual_network_name = "${local.vnet_name}"
  count = "${var.GatewaySubnet_cidr == "0" ? 1 : 0}"
}

resource "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = "${azurerm_resource_group.er_rg.name}"
  virtual_network_name = "${local.vnet_name}"
  address_prefix       = "${var.GatewaySubnet_cidr}"
  count = "${var.GatewaySubnet_cidr !=0 ? 1 : 0}"
}

locals {
  vnet_id = "${var.vnet_cidr == "0" ? 
    element(concat(data.azurerm_virtual_network.primary_vnet.*.id, list("")), 0) :
    element(concat(azurerm_virtual_network.primary_vnet.*.id, list("")), 0)}"

  vnet_name = "${var.vnet_cidr == "0" ? 
    element(concat(data.azurerm_virtual_network.primary_vnet.*.name, list("")), 0) :
    element(concat(azurerm_virtual_network.primary_vnet.*.name, list("")), 0)}"

  gateway_subnet_id = "${var.GatewaySubnet_cidr == "0" ?
    element(concat(data.azurerm_subnet.gateway_subnet.*.id, list("")), 0) :
    element(concat(azurerm_subnet.gateway_subnet.*.id, list("")), 0)}"

  gateway_subnet_cidr = "${var.GatewaySubnet_cidr == "0" ? 
   element(concat(data.azurerm_subnet.gateway_subnet.*.address_prefix, list("")), 0) :
   element(concat(azurerm_subnet.gateway_subnet.*.address_prefix, list("")), 0)}"
}

# Get information about an existing ER Gateway
data "azurerm_virtual_network_gateway" "expressroute_gateway" {
  name = "${var.express_route_gateway_name}"
  resource_group_name = "${azurerm_resource_group.er_rg.name}"
  count = "${var.express_route_gateway_name != "0" ? 1 : 0}"
}

# Create a new ER Gateway
module "expressroute_gateway" {
  source = "./gateway"

  vnet_name = "${local.vnet_name}"
  location = "${var.deployment_location}"
  resource_group_name = "${azurerm_resource_group.er_rg.name}"
  gateway_subnet_id = "${local.gateway_subnet_id}"

  # Ensure that there is no Gateway already present. If there is, then we need to ensure that it is not of type ExpressRoute Gateway in order to create a new one.
  create_new_gateway = "${var.express_route_gateway_name != "0" || element(concat(data.azurerm_virtual_network_gateway.expressroute_gateway.*.type, list("")), 0) == "ExpressRoute" ? 0: 1}"
}

data "azurerm_express_route_circuit" "ER_circuit" {
    resource_group_name = "${var.resource_group_name}"
    name = "${var.express_route_name}"
}

resource "azurerm_virtual_network_gateway_connection" "Az2OCI-ER-conn" {
  name                = "${var.resource_group_name}-Az2OCI-ER-conn"
  location            = "${var.deployment_location}"
  resource_group_name = "${var.resource_group_name}"
  type                       = "ExpressRoute"
  virtual_network_gateway_id = "${var.express_route_gateway_name == "0" ? 
    module.expressroute_gateway.vnet_gw_id : 
    element(concat(data.azurerm_virtual_network_gateway.expressroute_gateway.*.id, list("")), 0)}"
  express_route_circuit_id = "${data.azurerm_express_route_circuit.ER_circuit.id}"

  #The following boolean variable allows datapath connection to bypass VNet GW.
  express_route_gateway_bypass = "true"
  
  count = "${data.azurerm_express_route_circuit.ER_circuit.service_provider_provisioning_state == "Provisioned" ? 1 : 0}"
}
