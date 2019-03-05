resource "azurerm_virtual_machine" "toolsclient" {
  name                          = "${var.compute_hostname_prefix_tc}-${format("%.02d",count.index + 1)}"
  count                         = "${var.toolsclient_instance_count}"
  location                      = "${var.location}"
  resource_group_name           = "${var.resource_group_name}"
  vm_size                       = "${var.vm_size}"
  network_interface_ids         = ["${element(azurerm_network_interface.toolsclient.*.id, count.index)}"]
  delete_os_disk_on_termination = "true"

# Add cloud init
  storage_image_reference {
    publisher = "${var.os_publisher}"
    offer     = "${var.os_offer}"
    sku       = "${var.os_sku}"
    version   = "${var.os_version}"
}

  storage_os_disk {
    name              = "${var.compute_hostname_prefix_tc}-${format("%.02d",count.index + 1)}-disk-OS"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    disk_size_gb      = "${var.toolsclient_boot_volume_size_in_gb}"
    managed_disk_type = "${var.storage_account_type}"
  }

  os_profile {
    computer_name  = "${var.compute_hostname_prefix_tc}-${format("%.02d",count.index + 1)}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
    custom_data    = "${var.custom_data}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${file("${var.toolsclient_ssh_public_key}")}"
    }
  }

  tags = "${var.tags}"

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${var.boot_diag_SA_endpoint}"
      }
}


resource "azurerm_network_interface" "toolsclient" {
  name                          = "${var.compute_hostname_prefix_tc}-${format("%.02d",count.index + 1)}-nic"  
  count                         = "${var.toolsclient_instance_count}"
  location                      = "${var.location}"
  resource_group_name           = "${var.resource_group_name}"
  enable_accelerated_networking = "${var.enable_accelerated_networking}"

  ip_configuration {
    name                          = "ipconfig${count.index}"
    subnet_id                     = "${var.vnet_subnet_id}"
    private_ip_address_allocation = "Dynamic"
  }

  tags = "${var.tags}"
}
