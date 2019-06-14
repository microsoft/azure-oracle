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

variable "pvt_peering_primary_subnet" {
    description = "Private IP space of /30 for primary ExpressRoute circuit private peering. This should not overlap IP space used either in Azure VNets or OCI VCNs"
    default = "192.168.255.0/30"
}

variable "pvt_peering_secondary_subnet" {
    description = "Private IP space of /30 for secondary ExpressRoute circuit private peering. This should not overlap IP space used either in Azure VNets or OCI VCNs"
    default = "192.168.255.4/30"
}

variable "expressroute_sku" {
    description = "The ExpressRoute SKU to be created. Possible values are 'Standard' or 'Premium'"
}
    
variable "expressroute_billing_model" {
    description = "The ExpressRoute billing model to be used. Possible values are 'Unlimited' or 'MeteredData'"
}