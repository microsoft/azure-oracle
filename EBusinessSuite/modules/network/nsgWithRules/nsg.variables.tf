variable "nsg_name" {}
variable "location" {}
variable "resource_group_name" {}
variable "subnet_id" {}

variable "inboundOverrides" {
   type = "list" 
}

variable "outboundOverrides" {
   type = "list"
}