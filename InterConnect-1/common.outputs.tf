output "expressroute_name" {
    description = "ExpressRoute name being created"
    value = "${azurerm_express_route_circuit.Az2OCI.name}"
}
output "expressroute_service_key" {
    description = "ExpressRoute servicekey being created"
    value = "${azurerm_express_route_circuit.Az2OCI.service_key}"
}

output "expressroute_provider_status" {
    value = "${azurerm_express_route_circuit.Az2OCI.service_provider_provisioning_state}"
}
output "expressroute_circuit_id" {
    value = "${azurerm_express_route_circuit.Az2OCI.id}"
}
