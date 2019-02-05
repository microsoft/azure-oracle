variable "azure-region" {
    description = "Azure region to be deployed in",
    default = "East US"
}

variable "azure-tenant-id" {
    description = "Azure AD Tenant ID"
}

variable "azure-subscription-id" {
    description = "Azure Subscription ID"
}

variable "azure-sp-client-id" {
    description = "Azure Service Principal Client ID"
}

variable "azure-sp-client-secret" {
    description = "Azure Service Principal Client Secret"
}

variable "vpn-cidr" {
    description = "IP Address block in CIDR notation"
    default = "10.0.0.0/16"
}

variable "sub-cidr" {
    description = "IP Address blocks in CIDR notation for the subnets"
    defauly = {
        "pubcidr" = "10.0.4.0/24"
        "pvtcidr" = "10.0.5.0/24"
        "bastcidr" = "10.0.6.0/24"
        "dbcidr" = "10.0.7.0/24"    #Setting up DB IP Addresses in jdedeploy itself
    }
}


#Following variables are used to provide number of VM's to be created for each of the JDE server componennt

variable "jde_ent_count" {
  description = "Number of enterprise server to be provisioned in above specified Availability Domain"
  default = "0"
}

variable "jde_web_count" {
  description = "Number of Web server to be provisioned in above specified Availablity Domain"
  default = "0"
}


variable "jde_smc_count" {
   description = "Number of SMC server to be provisioned in above specified Availability Domain.Generally its recommended to use only one SMC in anyone of AD ehich will monitor JDE server accross domains"
   default = "0"
}

variable "computedb_count" {
  description = "Number of Compute DB VM's"
  default = "0"
}