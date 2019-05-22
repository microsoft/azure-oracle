output "vnet_name" {
    description = "VNET Name being created"
    value = "${azurerm_virtual_network.jde-vnet.name}"
}