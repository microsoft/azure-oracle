variable "tenant_id" {
    description = "Azure AD Tenant GUID for the provisioning subscription. e.g., 33311334-86f1-43af-91ab-2d7cd011d123"
}
variable "subscription_id" {
    description = "Azure Subscription GUID for the provisioning subscription. e.g., 666988bf-86f1-43af-91ab-2d7cd011db47"
}

variable "resource_group_name" {
    default = "ps-rg"
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
    application = "Oracle Peoplesoft"
  }
}

variable "create_public_ip" {
  default = false
}
variable "create_av_set" {
  default = true
}
variable "create_data_disk" {
  default = true
}

# Host Name Prefixes
variable "compute_hostname_prefix" {
 description = "Application server host resource prefix"
 default = "diag-sa"
}
variable "compute_hostname_prefix_app" {
  description = "Application server host resource prefix"
  default = "app"
}
variable "compute_hostname_prefix_bastion" {
  description = "Application server host resource prefix"
  default = "bastion"
}

variable "compute_hostname_prefix_web" {
  description = "Web server host resource prefix"
  default = "webserver"
}

variable "compute_hostname_prefix_es" {
  description = "Elastic Search server host resource prefix"
  default = "es"
}


variable "compute_hostname_prefix_ps" {
  description = "Elastic Search server host resource prefix"
  default = "ps"
}

variable "compute_hostname_prefix_tc" {
  description = "Elastic Search server host resource prefix"
  default = "tc"
}

# Set instance counts. 
#Min should be two for Application, Webserver, Elastic and ProSched due to Availablity Set usage.
variable "compute_instance_count" {
  description = "Application instance count"
  default = 2
}
variable "bastion_instance_count" {
  description = "Bastion instance count"
  default = 1
}

variable "webserver_instance_count" {
  description = "Webserver instance count"
  default = 2
}
variable "elastic_instance_count" {
  description = "elastic instance count"
  default = 2
}
variable "prosched_instance_count" {
  description = "elastic instance count"
  default = 2
}

variable "toolsclient_instance_count" {
  description = "elastic instance count"
  default = 1
}

# This template currently uses the same VM size for all instances, this may need to be customized futher.

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

# Set boot volume size for each instance type
variable "compute_boot_volume_size_in_gb" {
  description = "Boot volume size of compute instance"
  default = 128
}

variable "bastion_boot_volume_size_in_gb" {
  description = "Boot volume size of bastion instance"
  default = 128
}

variable "webserver_boot_volume_size_in_gb" {
  description = "Boot volume size of webserver instance"
  default = 128
}

variable "elastic_boot_volume_size_in_gb" {
  description = "Boot volume size of elastic search instance"
  default = 128
}
variable "prosched_boot_volume_size_in_gb" {
  description = "Boot volume size of elastic search instance"
  default = 128
}
variable "toolsclient_boot_volume_size_in_gb" {
  description = "Boot volume size of elastic search instance"
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

# Set SSH keys for each instance type.
variable "compute_ssh_public_key" {
  description = "Path to the public key to be used for ssh access to the VM."
  default     = "~/.ssh/id_rsa.pub"
}

variable "bastion_ssh_public_key" {
  description = "Path to the public key to be used for ssh access to the VM."
  default     = "~/.ssh/id_rsa.pub"
}

variable "webserver_ssh_public_key" {
  description = "Path to the public key to be used for ssh access to the VM."
  default     = "~/.ssh/id_rsa.pub"
}

variable "elastic_ssh_public_key" {
  description = "Path to the public key to be used for ssh access to the VM."
  default     = "~/.ssh/id_rsa.pub"
}
variable "prosched_ssh_public_key" {
  description = "Path to the public key to be used for ssh access to the VM."
  default     = "~/.ssh/id_rsa.pub"
}
variable "toolsclient_ssh_public_key" {
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
    default = "ps-vnet"
}
variable "vnet_cidr" {
    default = "10.2.0.0/16"
}






