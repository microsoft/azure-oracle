
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
  description = "Prefix for naming of each Application-server specific resource"
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
variable "toolsclient_boot_volume_size_in_gb" {
  description = "Boot volume size of compute instance"
}
variable "toolsclient_instance_count" {
  description = "Application instance count"
}
variable "admin_username" {
}
variable "admin_password" {
}
variable "custom_data" {
}
variable "toolsclient_ssh_public_key" {
  description = "Path to the public key to be used for ssh access to the VM."
}
variable "enable_accelerated_networking" {
}
variable "vnet_subnet_id" {
}
variable "prefix" {
  description = "(Required) Default prefix to use with your resource names."
  default     = "toolsclient"
}
variable "ip_sku" {
    default = "Standard"
}


variable "boot_diag_SA_endpoint" {

  description = "Blob endpoint for storage account to use for VM Boot diagnostics"

  type = "string"

}