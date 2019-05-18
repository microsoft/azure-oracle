/*output "expressroute_skey" {
    description = "Use the ExpressRoute service key below to provision Oracle FastConnect."
    value = "${module.create_ExR_ckt_to_OCI.expressroute_skey}"
}
output "expressroute_id" {
    description = "Use the following expressroute circuit id as input for the next run"
    value = "${module.create_ExR_ckt_to_OCI.expressroute_ckt_id}"
}

output "vnet_gw_id" {
    description = "Use the following VNet GW id as input for the next run"
    value = "${module.create_virtual_network_ExR_gw.vnet_gw_id}"
}*/

/*output "gateway_bypass" {
    value = "${data.azurerm_virtual_network_gateway.test.express_route_gateway_bypass}"
}*/

output "azurerm_express_route_circuit" {
    value = "${data.azurerm_express_route_circuit.test.location}"
}

output "azurerm_express_route_circuit_key" {
    value = "${data.azurerm_express_route_circuit.test.service_key}"
}