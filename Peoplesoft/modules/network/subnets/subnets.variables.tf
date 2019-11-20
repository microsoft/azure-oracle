variable "subnet_cidr_map" {
    description = "Map with Key = SubnetName, Value = subnet CIDR (address prefix)"
    type = "map"
}

variable "nsg_ids" {
   description = "Map of subnet names to NSGIDs"
   type = "map"
}
variable "nsg_ids_len" {
   description = "Number of entries in the nsg_id map"
}

# HouseKeeping...
variable "resource_group_name" {}
variable "vnet_name" {}
variable "vnet_cidr" {}


# Note: subnets don't include resource tags.
