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

variable "diag_storage_account_tier" {
    description = "Tier for boot diagnostics account.  One of 'Standard' or 'Premium'"
    default = "Standard"
}

variable "compute_hostname_prefix" {
    description = "Name prefix used for app VMs -- an anchor to generate the SA name"
    type = "string"
}