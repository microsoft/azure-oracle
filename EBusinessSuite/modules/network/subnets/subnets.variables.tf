variable "subnet_cidr_map" {
    description = "Map with Key = SubnetName, Value = subnet CIDR (address prefix)"
    type = "map"
}

variable "nsg_ids" {
   description = "Map of subnet names to NSGIDs"
   type = "map"
}

# HouseKeeping...
variable "resource_group_name" {}
variable "vnet_name" {}
