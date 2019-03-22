output "backendpool_id" {
    description = "Backend pool"
    value = "${azurerm_lb_backend_address_pool.azlb.id}"
}

output "appB_backendpool_id" {
    description = "Backend pool"
    value = "${azurerm_lb_backend_address_pool.appB.id}"
}

output "ria_backendpool_id" {
    description = "Backend pool"
    value = "${azurerm_lb_backend_address_pool.ria.id}"
}