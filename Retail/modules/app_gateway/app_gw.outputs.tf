
output "backendpool_address_pool_1_id" {
    value = "${azurerm_application_gateway.app_gw.backend_address_pool.0.id}"

}

output "backendpool_address_pool_2_id" {
    value = "${azurerm_application_gateway.app_gw.backend_address_pool.1.id}"
}


output "backendpool_address_pool_3_id" {
    value = "${azurerm_application_gateway.app_gw.backend_address_pool.2.id}"
}


output "backendpool_address_pool_4_id" {
   value = "${azurerm_application_gateway.app_gw.backend_address_pool.3.id}"
}