output "expressroute_name" {
    description = "ExpressRoute name being created"
    value = "${azurerm_express_route_circuit.Az2OCI.name}"
}
output "expressroute_skey" {
    description = "ExpressRoute servicekey being created"
    value = "${azurerm_express_route_circuit.Az2OCI.servicekey}"
}