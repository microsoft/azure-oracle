variable "nsg_rule_name" {}
variable "nsg_rule_priority" {}
variable "nsg_rule_direction" {}
variable "nsg_rule_access" {}
variable "nsg_rule_protocol" {}
variable "nsg_rule_source_port_range" {}
variable "nsg_rule_destination_port_range" {}
variable "nsg_rule_destination_port_ranges" {}
variable "nsg_rule_source_address_prefix" {}
variable "nsg_rule_destination_address_prefix" {}
variable "nsg_rule_source_address_prefixes" {}
variable "nsg_rule_destination_address_prefixes" {}
variable "resource_group_name" {}
variable "nsg_name" {}
variable "multiple_ports" {
    description = "Boolean value describing whether to create a rule for a single port/IP address range or multiple ports and ranges"
}