output "backend_ips" {
    # value = "${azurerm_network_interface.compute-public.*.private_ip_address}"
    value = "${concat(azurerm_network_interface.compute_private.*.private_ip_address, azurerm_network_interface.compute_public.*.private_ip_address)}"
}