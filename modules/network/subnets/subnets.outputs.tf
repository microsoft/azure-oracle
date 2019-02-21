output "subnet_ids" {
    value = "${zipmap(azurerm_subnet.subnet.*.name,azurerm_subnet.subnet.*.id)}"
}

#TODO: silly map
output "subnet_names" {
    value = "${zipmap(azurerm_subnet.subnet.*.name,azurerm_subnet.subnet.*.name)}"
}
output "subnet_prefix" {
    value = "${azurerm_subnet.subnet.*.address_prefix}"
}
