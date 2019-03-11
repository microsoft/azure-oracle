output "asg_id_ps" {
   # value = "${zipmap(azurerm_application.subnet.*.name,azurerm_subnet.subnet.*.id)}"
    value = "${azurerm_application_security_group.prosched.id}"
}

output "asg_id_app" {
   # value = "${zipmap(azurerm_application.subnet.*.name,azurerm_subnet.subnet.*.id)}"
    value = "${azurerm_application_security_group.compute.id}"
}

