variable "lb_name" {}
variable "resource_group_name" {}
variable "location" {}
variable "frontend_subnet_id" {}    # Only define this if creating an Internal Load Balancer
variable "create_public_load_balancer" {}
