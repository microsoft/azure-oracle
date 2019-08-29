variable "tenant_id" {
    description = "Azure AD Tenant GUID for the provisioning subscription. e.g., 33311334-86f1-43af-91ab-2d7cd011d123"
}

variable "subscription_id" {
    description = "Azure Subscription GUID for the provisioning subscription. e.g., 666988bf-86f1-43af-91ab-2d7cd011db47"
}

variable "client_id" {}
variable "client_secret" {}

variable "resource_group_name" {
    description = "Name of the resource group that will host the EBS Application"
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

variable "app_instance_count" {
  description = "Application instance count"
  default = 2
}

variable "enable_identity_integration" {
    description = "Boolean flag indicating whether Identity federation with IDCS or OAM is to be setup as a part of the application setup"
    default = true
}

variable "identity_instance_count" {
    description = "Instances of EBS Asserter (for IDCS) or Oracle HTTP Server/OAM WebGate (for OAM)"
    default = 2
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

variable "oci_vcn_name" {
    description = "The name of your Oracle Virtual Cloud Network. This will be used for DNS name resolution."
}

variable "oci_subnet_name" {
    description = "The name of your subnet in OCI where the DB will reside. This will be used for DNS name resolution."
}

variable "oci_db_subnet_cidr" {
    description = "The IP address space of your database subnet (or VNET IP Address space, if using Exadata Cloud Service) in CIDR notation."
}

variable "db_name" {
    description = "The name of your database in OCI."
}

variable "subnet_bits" {
    default = 3
    description = "Enter the bits for the subnet. E.x: if you'd like 8 IP addresses per subnet, enter 3 (2^3 = 8). If you'd like 16 IP addresses per subnet, enter 4 (2^4=16). Azure reserves 5 IP addresses from each subnet."
}

variable "db_scan_ip_addresses" {
    type = "list",
    description = "Enter the scan IP addresses of the Database for DNS resolution"
}