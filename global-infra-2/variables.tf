variable "tenant_id" {
    description = "Azure Active Directory Tenant ID"
}
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "environment" {
    description = "Whether it is dev/test/production"
}
variable "deployment_location" {
    description = "Location/region of deployment"
}
variable "resource_group_name" {
    description = "The name of the resource group"
}
variable "pvt_peering_subnet" {
    description = "Private IP space of /29 for primary and secondary ExpressRoute circuit private peering. This should not overlap IP space used either in Azure VNets or OCI VCNs"
    default = "192.168.255.0/29"
}
variable "pvt_peering_vlanID" {
    description = "This needs to match the value specified under OCI FastConnect"
    default = 100
}
variable "Vnet_GW_id" {}
variable "ExR_ckt_id" {}