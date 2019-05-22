variable "tenant_id" {
    description = "Azure Active Directory Tenant ID"
}
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "deployment_tag" {
    description = "A tag for your Azure deployment"
}

variable "resource_group_name" {
    description = "The name of the resource group"
}

variable "deployment_location" {
    description = "Location/region of deployment"
}

variable "peering_location" {
    description = "The name of the peering location and not the Azure resource location."
}

variable "bandwidth_in_mbps" {
    description = "The bandwidth in Mbps of the circuit being created. Gbps is represented in the nearest 1000s. E.g.: 1 Gbps = 1000 Mbps"
}

variable "pvt_peering_subnet" {
    description = "Private IP space of /29 for primary and secondary ExpressRoute circuit private peering. This should not overlap IP space used either in Azure VNets or OCI VCNs"
    default = "192.168.255.0/29"
}
variable "pvt_peering_vlanID" {
    description = "This needs to match the value specified under OCI FastConnect"
    default = 100
}