variable "vnet_name" {}
variable "vnet_cidr" {}

# Housekeeping
variable "resource_group_name" {}
variable "location" {}
variable "tags" {
    description = "ARM resource tags to any resource types which accept tags"
    type = "map"
}