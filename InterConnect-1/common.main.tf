resource "azurerm_resource_group" "er_rg" {
  name = "${var.resource_group_name}"
  location = "${var.deployment_location}"
}

# Create the ExpressRoute circuit to OCI under a resource group
resource "azurerm_express_route_circuit" "Az2OCI" {
  name                  = "${azurerm_resource_group.er_rg.name}-Az2OCI-ER-Circuit"
  resource_group_name   = "${azurerm_resource_group.er_rg.name}"
  location              = "${var.deployment_location}"
  service_provider_name = "Test Provider With Charges"  #The service provider name will later be changed to 'Oracle Cloud Infrastructure'
  peering_location      = "${var.peering_location}"
  bandwidth_in_mbps     = "${var.bandwidth_in_mbps}"

  sku {
    tier   = "Standard"  #This needs to be changed to 'local' or its equivalent
    family = "MeteredData"
  }
}

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
