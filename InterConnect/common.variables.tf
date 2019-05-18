variable "tenant_id" {
    description = "Azure Active Directory Tenant ID"
}
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "deployment_tag" {
    description = "A tag for your Azure deployment"
}
variable "deployment_location" {
    description = "Location/region of deployment"
}
variable "resource_group_name" {
    description = "The name of the resource group"
}

variable "vnet_name" {
    description = "The name of the VNET to be created/existing VNET"
}

variable "peering_location" {
    description = "The name of the peering location and not the Azure resource location."
}

variable "bandwidth_in_mbps" {
    description = "The bandwidth in Mbps of the circuit being created. Gbps is represented in the nearest 1000s. E.g.: 1 Gbps = 1000 Mbps"
}

variable "vnet_cidr" {
    description = "The IP Address space for your VNET in CIDR notation. You may enter '0' for an existing VNET if you do not have the IP address space handy."
}

variable "GatewaySubnet_cidr" {
    description = "The IP Address space for your GatewaySubnet in CIDR notation. e.g.: 192.168.1.0/27. A Minimum of /27 is required. You may enter a '0' if you have already provisioned a GatewaySubnet in your VNET"
}

variable "er_gateway_name" {
    description = "The name of an existing ExpressRoute Gateway. Enter a '0' if you do not have an existing ExpressRoute Gateway setup in your VNET."
    default = "0"
}


variable "pvt_peering_subnet" {
    description = "Private IP space of /29 for primary and secondary ExpressRoute circuit private peering. This should not overlap IP space used either in Azure VNets or OCI VCNs"
    default = "192.168.255.0/29"
}
variable "pvt_peering_vlanID" {
    description = "This needs to match the value specified under OCI FastConnect"
    default = 100
}


/*variable "Vnet_GW_id" {}
variable "ExR_ckt_id" {}*/