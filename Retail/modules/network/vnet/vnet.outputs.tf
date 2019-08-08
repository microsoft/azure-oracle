####################################
##  Output basic VNET Info
####################################
output "vnet_name" {
    description = "VNET Name being created"
    value = "${azurerm_virtual_network.vnet.name}"
}

output "vnet_cidr" {
    description = "VNET CIDR"
    value = "${azurerm_virtual_network.vnet.address_space}"
}