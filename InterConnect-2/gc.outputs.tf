output "express_route_gateway_connection_id" {
    value = "${data.azurerm_express_route_circuit.ER_circuit.service_provider_provisioning_state == "Provisioned" ? 
        element(concat(azurerm_virtual_network_gateway_connection.Az2OCI-ER-conn.*.id, list("")), 0) : 
        "Service Provider has NOT provisioned the Express Route Circuit yet. Gateway Connection cannot be established at this time. Please try again later."}"
}