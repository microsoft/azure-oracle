resource "random_id" "vm-sa" {
  keepers = {
      tmp = "${var.compute_hostname_prefix_bastion}"
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


resource "azurerm_virtual_machine" "bastion" {
  name                          = "${var.compute_hostname_prefix_bastion}-${format("%.02d",count.index + 1)}"
  count                         = "${var.bastion_instance_count}"
  location                      = "${var.location}"
  resource_group_name           = "${var.resource_group_name}"
  vm_size                       = "${var.vm_size}"
  network_interface_ids         = ["${element(azurerm_network_interface.bastion.*.id, count.index)}"]
  delete_os_disk_on_termination = "true"

# Add cloud init
  storage_image_reference {
    publisher = "${var.os_publisher}"
    offer     = "${var.os_offer}"
    sku       = "${var.os_sku}"
    version   = "${var.os_version}"
}

  storage_os_disk {
    name              = "${var.compute_hostname_prefix_bastion}-${format("%.02d",count.index + 1)}-disk-OS"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    disk_size_gb      = "${var.bastion_boot_volume_size_in_gb}"
    managed_disk_type = "${var.storage_account_type}"
  }

  os_profile {
    computer_name  = "${var.compute_hostname_prefix_bastion}-${format("%.02d",count.index + 1)}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
    custom_data    = "${var.custom_data}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${file("${var.bastion_ssh_public_key}")}"
    }
  }

  tags = "${var.tags}"

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.vm-sa.primary_blob_endpoint}"
    # storage_uri = "${join(",", azurerm_storage_account.vm-sa.*.primary_blob_endpoint)}"}
  }
}


resource "azurerm_network_interface" "bastion" {
  name                          = "${var.compute_hostname_prefix_bastion}-${format("%.02d",count.index + 1)}-nic"  
  count                         = "${var.bastion_instance_count}"
  location                      = "${var.location}"
  resource_group_name           = "${var.resource_group_name}"
  enable_accelerated_networking = "${var.enable_accelerated_networking}"

  ip_configuration {
    name                          = "ipconfig${count.index}"
    subnet_id                     = "${var.vnet_subnet_id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.bastion.id}"
  }

  tags = "${var.tags}"
}
resource "azurerm_public_ip" "bastion" {
  name                         = "${var.prefix}-public-ip"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  allocation_method            = "${var.public_ip_address_allocation}"
  tags                         = "${var.tags}"
  sku                          = "${var.ip_sku}"
}