variable "nsg_name" {}

variable "subnet_id" {}

variable "inboundOverrides" {
   type = "list" 
}

variable "outboundOverrides" {
   type = "list"
}

# Housekeeping
variable "location" {}
variable "resource_group_name" {}

variable "tags" {
  description = "ARM resource tags to any resource types which accept tags"
  type = "map"
}