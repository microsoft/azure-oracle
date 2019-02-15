output "nsg_id" {
    value = "${azurerm_network_security_group.jde-nsg.id}"
}

output "nsg_name" {
    value = "${azurerm_network_security_group.jde-nsg.name}"
}