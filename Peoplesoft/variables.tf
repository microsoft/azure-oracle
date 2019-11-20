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
    default = "ps-rg-vms"
}

variable "vnet_resource_group_name" {
    default = "ps-rg-vnet"
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


# Set instance counts. 
#Min should be two for Application, Webserver, Elastic and ProSched due to Availablity Set usage.
variable "compute_instance_count" {
  description = "Instance count for VMs"
  default = 2
}

# This template currently uses the same VM size for all instances, this may need to be customized futher.

variable "vm_size" {
    # default = "Standard_D2_v2"
    default = "Standard_E16-8s_v3"
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
variable "os_volume_size_in_gb" {
  description = "Boot volume size of compute instance"
  default = 128
}

variable "data_disk_size_gb" {
    default = 256
}
variable "data_sa_type" {
    default = "StandardSSD_LRS"
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
    default =  "10.2.0.0/16"
    description = "Enter a '0' if the VNET already exists. Currently, only VNETs with 1 address space are supported."
}

variable "oci_vcn_name" {
}

variable "oci_subnet_name" {

}

variable "db_scan_ip_addresses" {

}
variable "db_name" {
  
}



