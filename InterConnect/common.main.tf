resource "azurerm_resource_group" "er_rg" {
  name = "${var.resource_group_name}"
  location = "${var.deployment_location}"
}

# To do, before public preview,
#     change the service provider name
#     change the SKU to local or its equivalent (check w/ Karthik)
# Create the ExpressRoute circuit to OCI under a resource group
resource "azurerm_express_route_circuit" "Az2OCI" {
  name                  = "${azurerm_resource_group.er_rg.name}-Az2OCI-ER-Circuit"
  resource_group_name   = "${azurerm_resource_group.er_rg.name}"
  location              = "${var.deployment_location}"
  service_provider_name = "Test Provider With Charges"
  peering_location      = "${var.peering_location}"
  bandwidth_in_mbps     = "${var.bandwidth_in_mbps}"

  sku {
    tier   = "Standard"
    family = "MeteredData"
  }
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

 /* vnet_address_space = "${var.vnet_cidr == "0" ? 
    element(concat(element(data.azurerm_virtual_network.primary_vnet.*.address_spaces, 0), list("")), 0) :
    element(concat(azurerm_virtual_network.primary_vnet.*.address_space, list("")), 0)}"
*/

  gateway_subnet_id = "${var.GatewaySubnet_cidr == "0" ?
    element(concat(data.azurerm_subnet.gateway_subnet.*.id, list("")), 0) :
    element(concat(azurerm_subnet.gateway_subnet.*.id, list("")), 0)}"

  gateway_subnet_cidr = "${var.GatewaySubnet_cidr == "0" ? 
   element(concat(data.azurerm_subnet.gateway_subnet.*.address_prefix, list("")), 0) :
   element(concat(azurerm_subnet.gateway_subnet.*.address_prefix, list("")), 0)}"
}

# Get information about an existing ER Gateway
data "azurerm_virtual_network_gateway" "expressroute_gateway" {
  name = "${var.er_gateway_name}"
  resource_group_name = "${azurerm_resource_group.er_rg.name}"
  count = "${var.er_gateway_name != "0" ? 1 : 0}"
}

# Create a new ER Gateway  //Start here: Create an ER Gateway
module "expressroute_gateway" {
  source = "./gateway"

  vnet_name = "${local.vnet_name}"
  location = "${var.deployment_location}"
  resource_group_name = "${azurerm_resource_group.er_rg.name}"
  gateway_subnet_id = "${local.gateway_subnet_id}"
  create_new_gateway = "${var.er_gateway_name != "0" || element(concat(data.azurerm_virtual_network_gateway.expressroute_gateway.*.type, list("")), 0) == "ExpressRoute" ? 0: 1}"
}


# *************************************
# This segment is a hack and will not be needed after announcement
# Create a temp VNET in order to enable ExpressRoute Gateway Bypass.

resource "azurerm_virtual_network" "temporary_vnet" {
  name = "Temp-VNET"
  resource_group_name = "${azurerm_resource_group.er_rg.name}"
  location = "${var.deployment_location}"
  address_space = ["172.16.255.128/25"]
}

resource "azurerm_virtual_network_peering" "test1" {
  name                      = "peer1to2"
  resource_group_name       = "${azurerm_resource_group.er_rg.name}"
  virtual_network_name      = "${local.vnet_name}"
  remote_virtual_network_id = "${azurerm_virtual_network.temporary_vnet.id}"
  
  depends_on = ["azurerm_subnet.gateway_subnet"]
}

resource "azurerm_virtual_network_peering" "test2" {
  name                      = "peer2to1"
  resource_group_name       = "${azurerm_resource_group.er_rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.temporary_vnet.name}"
  remote_virtual_network_id = "${local.vnet_id}"

  depends_on = ["azurerm_subnet.gateway_subnet"]
}

# *************************************
# End of hack section

     
# Create private peering under our ExpressRoute circuit
resource "azurerm_express_route_circuit_peering" "test" {
  peering_type                  = "AzurePrivatePeering"
  express_route_circuit_name    = "${azurerm_express_route_circuit.Az2OCI.name}"
  resource_group_name           = "${azurerm_resource_group.er_rg.name}"
  peer_asn                      = 31898 #ASN of Oracle
  primary_peer_address_prefix   = "${cidrsubnet(var.pvt_peering_subnet, 1, 0)}"
  secondary_peer_address_prefix = "${cidrsubnet(var.pvt_peering_subnet, 1, 1)}"
  vlan_id                       = "${var.pvt_peering_vlanID}"
}


# Start here: This is only possible when the circuit is provisioned. Need to remove this from here and add it to a new file where we first do a data for express route and then do gateway connection
/*
resource "azurerm_virtual_network_gateway_connection" "Az2OCI-ER-conn" {
  name                = "${var.resource_group_name}-Az2OCI-ER-conn"
  location            = "${var.deployment_location}"
  resource_group_name = "${azurerm_resource_group.er_rg.name}"

  type                       = "ExpressRoute"
  virtual_network_gateway_id = "${var.er_gateway_name == "0" ?
    element(concat(data.azurerm_virtual_network_gateway.expressroute_gateway.*.id, list("")), 0) :
    module.expressroute_gateway.vnet_gw_id}"


  express_route_circuit_id = "${azurerm_express_route_circuit.Az2OCI.id}"

  #The following boolean variable allows datapath connection to bypass VNet GW.
  express_route_gateway_bypass = "true"
} */