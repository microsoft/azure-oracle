module "create_pvt_peering" {
  source = "./private_peering"
  
    expressroute-circuit-name = "${var.resource_group_name}-Az2OCI-ER"
    resource-group-name = "${var.resource_group_name}"
    primary-subnet = "${cidrsubnet(var.pvt_peering_subnet, 1, 0)}"
    secondary-subnet = "${cidrsubnet(var.pvt_peering_subnet, 1, 1)}"
    vlan-id = "${var.pvt_peering_vlanID}"
}

resource "azurerm_virtual_network_gateway_connection" "Az2OCI-ER-conn" {
  name                = "${var.resource_group_name}-Az2OCI-ER-conn"
  location            = "${var.deployment_location}"
  resource_group_name = "${var.resource_group_name}"

  type                       = "ExpressRoute"
  virtual_network_gateway_id = "${var.Vnet_GW_id}"
  express_route_circuit_id = "${var.ExR_ckt_id}"

  #The following boolean variable allows datapath connection to bypass VNet GW.
  #express_route_gateway_bypass = "true"
}