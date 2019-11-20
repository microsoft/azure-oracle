output "nsg_id" {
    value = "${element(concat(azurerm_network_security_group.nsg.*.id, list("0")), 0)}"
}

output "nsg_name" {
    value = "${element(concat(azurerm_network_security_group.nsg.*.name, list("0")), 0)}"
}

output "subnet_id" {
    value = "${element(concat(azurerm_subnet.subnet.*.id, list("0")), 0)}"
}