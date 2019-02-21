variable "vm_hostname" {
  description = "VM Hostname"
}
variable "resource_group_name" {
}
variable "location" {
}
variable "tags" {
}
variable "compute_hostname_prefix" {
  description = "Application hostname prefix"
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
}
variable "data_sa_type" {
}
variable "admin_username" {
}
variable "admin_password" {
}
variable "custom_data" {
}
variable "compute_ssh_public_key" {
  description = "SSH public key"
}
variable "nb_instances" {
}
variable "enable_accelerated_networking" {
}
variable "vnet_subnet_id" {
}




variable "compute_ssh_private_key" {
  description = "SSH private key"
}

variable "compute_instance_listen_port" {
  description = "Application instance listen port"
}
variable "bastion_ssh_private_key" {
  description = "SSH key"
}
variable "compute_subnet" {
  description = "subnet"
  type        = "list"
}
variable "bastion_public_ip" {
  description = "Public IP of bastion instance"
}
variable "fss_primary_mount_path" {
  description = "Mountpoint for primary application servers"
}
variable "fss_instance_prefix" {
  description = "FSS instance name prefix"
}
variable "fss_subnet" {
  description = "FSS subnet"
  type        = "list"
}
variable "fss_limit_size_in_gb" {}
variable "timeout" {
  description = "Timeout setting for resource creation "
  default     = "20m"
}
variable "compute_instance_user" {
  description = "Login user for compute instance"
}

variable "timezone" {
    description = "Set timezone for compute instance"
}
variable "bastion_user" {
  description = "Login user for bastion host"
}