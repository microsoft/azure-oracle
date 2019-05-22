variable "tenant_id" {
    description = "Azure Active Directory Tenant ID"
}
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "resource_group_name" {}
variable "deployment_location" {}
variable "express_route_name" {}
variable "vnet_name" {
    description = "The name of the VNET to be created/existing VNET"
}
variable "vnet_cidr" {
    description = "The IP Address space for your VNET in CIDR notation. You may enter '0' for an existing VNET if you do not have the IP address space handy."
}

variable "GatewaySubnet_cidr" {
    description = "The IP Address space for your GatewaySubnet in CIDR notation. e.g.: 192.168.1.0/27. A Minimum of /27 is required. You may enter a '0' if you have already provisioned a GatewaySubnet in your VNET"
}

variable "express_route_gateway_name" {
    description = "The name of an existing ExpressRoute Gateway. Enter a '0' if you do not have an existing ExpressRoute Gateway setup in your VNET."
    default = "0"
}