####################################
##  Output basic VNET Info
####################################
output "vnet_name" {
    description = "VNET Name being created"
    value = "${azurerm_virtual_network.primary_vnet.*.name}"
}

output "vnet_cidr" {
    description = "VNET CIDR"
    value = "${azurerm_virtual_network.primary_vnet.*.address_space}"
}

