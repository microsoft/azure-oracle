variable "tier_name" {}
variable "vnet_name" {}
variable "address_prefix" {}
variable "inboundOverrides" {
   type = "list" 
}

variable "outboundOverrides" {
   type = "list"
}

# Housekeeping
variable "location" {}
variable "resource_group_name" {}

variable "vnet_rg_name" {
  description = "The name of the resource group that contains the VNET"
}

variable "tags" {
  description = "ARM resource tags to any resource types which accept tags"
  type = "map"
}

variable "createSubnetAndNSG" {
}