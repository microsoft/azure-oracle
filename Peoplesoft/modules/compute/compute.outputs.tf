output "backend_ips" {
    value = "${azurerm_network_interface.compute.*.private_ip_address}"
}