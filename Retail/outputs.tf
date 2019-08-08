##  Output basic VNET Info

output "vnet_name" {
    description = "VNET Name being created"
    value = "${azurerm_virtual_network.vnet.name}"
}

output "vnet_cidr" {
    description = "VNET CIDR"
    value = "${azurerm_virtual_network.vnet.address_space}"
}
### LB Outputs

output "loadbalancer_id" {
    description = "LB id"
    value = "${azurerm_lb.inlb.id}" 
    
}
output "lb_frontend_ips" {
    value = "${azurerm_lb.inlb.private_ip_addresses}"
}