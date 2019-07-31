output "vm_ids" {
    description = "Names of the VMs that are created"
    value = "${concat(azurerm_virtual_machine.compute-as.*.id, azurerm_virtual_machine.compute-az.*.id)}"
}

output "vm_nics" {
   description = "the NIC IDs of the VMs that are created"
   value = "${concat(azurerm_network_interface.nic.*.id, azurerm_network_interface.public_nic.*.id)}" 
}