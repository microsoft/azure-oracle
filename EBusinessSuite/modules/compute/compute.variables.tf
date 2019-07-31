
variable "resource_group_name" {
}
variable "location" {
}
variable "tags" {
  type = "map"

  default = {
    application = "Oracle EBusinessSuite"
  }
}
variable "compute_hostname_prefix" {
  description = "Prefix for naming of each server specific resource"
}
variable "instance_count" {
  description = "Application instance count"
}



variable "vm_size" {
}
variable "os_publisher" {
}
variable "os_offer" {
}
variable "os_sku" {
}
variable "os_version" {

}
variable "storage_account_type" {
}
variable "boot_volume_size_in_gb" {
  description = "Boot volume size of compute instance"
}

variable "attach_data_disks" {
  description = "Whether a data disk needs to attached to the VM"
}
variable "data_disk_size_gb" {
}
variable "data_sa_type" {
}
variable "admin_username" {
}
//variable "admin_password" {
//}
variable "custom_data" {
}
variable "ssh_public_key" {
  description = "Path to the public key to be used for ssh access to the VM."
}
variable "enable_accelerated_networking" {
}
variable "vnet_subnet_id" {
}

variable "boot_diag_SA_endpoint" {
  description = "Blob endpoint for storage account to use for VM Boot diagnostics"
  type = "string"
}

variable "assign_public_ip" {
  description = "Whether or not the VMs need to have a public IP"
}

variable "public_ip_address_allocation" {
  description = "Defines how a private IP address is assigned. Options are Static or Dynamic."
}

variable "public_ip_sku" {
  description = "The SKU for the public IP."
  default = "Standard"
}

#TODO
/*
variable "network_security_group_id" {

}
*/