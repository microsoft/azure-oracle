#
#  Create a storage account for boot diagnostics.
#

resource "random_id" "vm-sa" {
  keepers = {
      tmp = "${var.compute_hostname_prefix}"
  }

  byte_length = 8
}

resource "azurerm_storage_account" "vm-sa" {
  name                     = "bootdiag${lower(random_id.vm-sa.hex)}"
  resource_group_name      = "${var.resource_group_name}"
  location                 = "${var.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = "${var.tags}"
}