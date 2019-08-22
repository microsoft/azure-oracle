
variable "resource_group_name" {
}
variable "location" {
}
variable "tags" {
  type = "map"

  default = {
    application = "Oracle Peoplesoft"
  }
}
variable "compute_hostname_prefix" {
  description = "Prefix for naming of each Application-server specific resource"
}
variable "compute_instance_count" {
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
variable "compute_boot_volume_size_in_gb" {
  description = "Boot volume size of compute instance"
}
variable "data_disk_size_gb" {
    default = 128
}
variable "data_sa_type" {
    default = "Standard_LRS"
}
variable "admin_username" {
}
variable "admin_password" {
}
variable "custom_data" {
}
variable "compute_ssh_public_key" {
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
variable "backendpool_id" {
  default = "0"
}
variable "create_public_ip" {

}
variable "public_ip_address_allocation" {
   default = "Static"
}
variable "ip_sku" {
    default = "Standard"
}
variable "create_av_set" {

}
variable "create_data_disk" {

}
variable "assign_bepool" {

}
variable "create_vm" {
  
}