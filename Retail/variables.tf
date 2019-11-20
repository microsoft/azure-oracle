variable "tenant_id" {
    description = "Azure AD Tenant GUID for the provisioning subscription. e.g., 33311334-86f1-43af-91ab-2d7cd011d123"
}

variable "subscription_id" {
    description = "Azure Subscription GUID for the provisioning subscription. e.g., 666988bf-86f1-43af-91ab-2d7cd011db47"
}


variable "client_secret" {
  
}

variable "client_id" {
}


variable "resource_group_name" {
    default = "retail-rg-vms"
}

variable "vnet_resource_group_name" {
    default = "retail-rg-vnet"
    description = "Name of the Resource Group where the VNET is/will be located. This can be same as the app resource group or different."
}
variable "lb_sku" {
    default = "Standard"

}
variable "location" {
    description = "Azure region"
}
variable "tags" {
  description = "ARM resource tags to any resource types which accept tags"
  type = "map"

  default = {
    application = "Oracle Retail"
  }
}

variable "compute_instance_count" {
  description = "Application instance count"
  default = 2
}


variable "vm_size" {
    default = "Standard_F4s"
}
variable "os_publisher" {
    default = "Oracle"
}
variable "os_offer" {
    default = "Oracle-Linux"
}
variable "os_sku" {
    default = "7.6"
}
variable "os_version" {
    default = "latest"

}
variable "storage_account_type" {
    default = "Standard_LRS"
}
variable "os_volume_size_in_gb" {
  description = "Boot volume size of instance"
  default = 128
}

variable "data_disk_size_gb" {
    default = 128
}
variable "data_sa_type" {
    default = "Standard_LRS"
}
variable "admin_username" {
    default = "sysadmin"
}
variable "admin_password" {
}
variable "custom_data" {
}
variable "compute_ssh_public_key" {
  description = "Path to the public key to be used for ssh access to the VM."
  default     = "~/.ssh/id_rsa.pub"
}


variable "enable_accelerated_networking" {
    default = "false"
}
variable "vnet_name" {
    default = "retail-vnet"
}
variable "vnet_cidr" {
    default = "10.2.0.0/16"
}

variable "frontend_name" {
  default = "app-lb"
}

variable "create_public_ip" {
  default = false
}

variable "create_data_disk" {
  default = true
}

variable "prefix" {
  description = "(Required) Default prefix to use with your resource names."
  default     = "azure_lb"
}





