# To do, before public preview,
#     
# Create private peering under Az2OCI-ER circuit
resource "azurerm_express_route_circuit_peering" "test" {
  peering_type                  = "AzurePrivatePeering"
  express_route_circuit_name    = "${var.expressroute-circuit-name}"
  resource_group_name           = "${var.resource-group-name}"
  peer_asn                      = 31898 #ASN of Oracle
  primary_peer_address_prefix   = "${var.primary-subnet}"
  secondary_peer_address_prefix = "${var.secondary-subnet}"
  vlan_id                       = "${var.vlan-id}"
}