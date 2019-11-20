variable "tenant_id" {
    description = "Azure AD Tenant GUID for the provisioning subscription. e.g., 33311334-86f1-43af-91ab-2d7cd011d123"
}

variable "subscription_id" {
    description = "Azure Subscription GUID for the provisioning subscription. e.g., 666988bf-86f1-43af-91ab-2d7cd011db47"
}

variable "client_id" {}
variable "client_secret" {}

variable "resource_group_name" {
    default = "ebs-rg"
}

variable "vnet_resource_group_name" {
    description = "Name of the Resource Group where the VNET is/will be located. This can be same as the app resource group or different."
}

variable "lb_sku" {
    default = "Standard"

}
variable "location" {
    description = "Azure region"
    default = "East US"
}
variable "tags" {
  description = "ARM resource tags to any resource types which accept tags"
  type = "map"

  default = {
    application = "Oracle EBusinessSuite"
  }
}

variable "vm_hostname_prefix_app" {
  description = "Application server host resource prefix"
  default = "app"
}
variable "vm_hostname_prefix_bastion" {
  description = "Bastion server host resource prefix"
  default = "bastion"
}

variable "vm_hostman_prefix_identity" {
    description = "Identity Server Host resource prefix"
}

variable "app_instance_count" {
  description = "Application instance count"
  default = 2
}

variable "identity_instance_count" {
    description = "Instances of EBS Asserter (for IDCS) or Oracle HTTP Server/OAM WebGate (for OAM)"
    default = 2
}
variable "bastion_instance_count" {
  description = "Bastion instance count"
  default = 1
}

variable "vm_size" {
    default = "Standard_D2_V2"
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
variable "compute_boot_volume_size_in_gb" {
  description = "Boot volume size of compute instance"
  default = 128
}

variable "bastion_boot_volume_size_in_gb" {
  description = "Boot volume size of bastion instance"
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
variable "custom_data" {
    description = " Specifies custom data to supply to the machine. On Linux-based systems, this can be used as a cloud-init script. On other systems, this will be copied as a file on disk. Internally, Terraform will base64 encode this value before sending it to the API. The maximum length of the binary array is 65535 bytes."
}
variable "compute_ssh_public_key" {
  description = "Path to the public key to be used for ssh access to the VM."
  default     = "~/.ssh/id_rsa.pub"
}

variable "bastion_ssh_public_key" {
  description = "Path to the public key to be used for ssh access to the VM."
  default     = "~/.ssh/id_rsa.pub"
}
variable "nb_instances" {
    default = 1
}
variable "enable_accelerated_networking" {
    default = "false"
}
variable "vnet_name" {
    default = "ebs-vnet"
}
variable "vnet_cidr" {
    default = "10.2.0.0/16"
    description = "Enter a '0' if the VNET already exists. Currently, only VNETs with 1 address space are supported."
}

variable "database_in_azure" {
    default = false
}



