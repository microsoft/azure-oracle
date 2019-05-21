output "loadbalancer_id" {
    description = "LB id"
    value = "${azurerm_lb.inlb.id}" 
    
}
output "lb_frontend_ips" {
    value = "${azurerm_lb.inlb.private_ip_addresses}"
}