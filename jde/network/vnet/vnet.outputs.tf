output "vnet_name" {
    description = "VNET Name being created"
    value = "${azurerm_virtual_network.jde-vnet.name}"
}

output "vnet_id" {
    description = "VNet id being created"
    value = "${azurerm_virtual_network.jde-vnet.id}"
}