variable "subnet_cidr_map" {
    description = "Map with Key = subnet name, Value = subnet CIDR (address prefix, e.g. 1.2.3.0/24)"
    type = "map"
}

variable "nsg_ids" {
   description = "Map of subnet names to NSG IDs"
   type = "map"
}

variable "nsg_ids_len" {
   description = "Number of entries in the nsg_id map"
}

# HouseKeeping...
variable "resource_group_name" {}
variable "vnet_name" {}

# Note: subnets don't include resource tags.
