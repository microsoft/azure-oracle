# Used for VMs that need AVsets
resource "azurerm_virtual_machine" "compute" {
  name                          = "${var.compute_hostname_prefix}-${format("%.02d",count.index + 1)}"
  count                         = "${var.compute_instance_count * var.create_av_set}"
  location                      = "${var.location}"
  resource_group_name           = "${var.resource_group_name}"
  availability_set_id           = "${azurerm_availability_set.compute.id}"
  vm_size                       = "${var.vm_size}"
  network_interface_ids         = ["${element(azurerm_network_interface.compute.*.id, count.index)}"]
  delete_os_disk_on_termination = "true"

# Add cloud init
  storage_image_reference {
    publisher = "${var.os_publisher}"
    offer     = "${var.os_offer}"
    sku       = "${var.os_sku}"
    version   = "${var.os_version}"
}

  storage_os_disk {
    name              = "${var.compute_hostname_prefix}-${format("%.02d",count.index + 1)}-disk-OS"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    disk_size_gb      = "${var.compute_boot_volume_size_in_gb}"
    managed_disk_type = "${var.storage_account_type}"
  }

  os_profile {
    computer_name  = "${var.compute_hostname_prefix}-${format("%.02d",count.index + 1)}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
    custom_data    = "${var.custom_data}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${file("${var.compute_ssh_public_key}")}"
    }
  }

  tags = "${var.tags}"

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${var.boot_diag_SA_endpoint}"
  }
}

# Used only for VMs that do not use AVsets
resource "azurerm_virtual_machine" "compute_no_avset" {
  name                          = "${var.compute_hostname_prefix}-${format("%.02d",count.index + 1)}"
  count                         = "${var.create_av_set ? 0 : 1}"
  location                      = "${var.location}"
  resource_group_name           = "${var.resource_group_name}"
  vm_size                       = "${var.vm_size}"
  network_interface_ids         = ["${element(azurerm_network_interface.compute.*.id, count.index)}"]
  delete_os_disk_on_termination = "true"

  # Add cloud init
  storage_image_reference {
    publisher = "${var.os_publisher}"
    offer     = "${var.os_offer}"
    sku       = "${var.os_sku}"
    version   = "${var.os_version}"
}

  storage_os_disk {
    name              = "${var.compute_hostname_prefix}-${format("%.02d",count.index + 1)}-disk-OS"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    disk_size_gb      = "${var.compute_boot_volume_size_in_gb}"
    managed_disk_type = "${var.storage_account_type}"
  }

  os_profile {
    computer_name  = "${var.compute_hostname_prefix}-${format("%.02d",count.index + 1)}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
    custom_data    = "${var.custom_data}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${file("${var.compute_ssh_public_key}")}"
    }
  }

  tags = "${var.tags}"

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${var.boot_diag_SA_endpoint}"
  }
}

 # Data Disk Attachements
resource "azurerm_managed_disk" "vm_data_disks" {
    name                 = "${var.compute_hostname_prefix}-${format("%.02d",count.index + 1)}-disk-data-01"  
    location             = "${var.location}"
    resource_group_name  = "${var.resource_group_name}"
    storage_account_type = "${var.storage_account_type}"
    create_option        = "Empty"
    disk_size_gb         = "${var.data_disk_size_gb}"
    # count                = "${var.create_data_disk}"
    count                = "${var.compute_instance_count * var.create_data_disk}"

}

resource "azurerm_virtual_machine_data_disk_attachment" "vm_data_disks_attachment" {
  managed_disk_id    = "${element(azurerm_managed_disk.vm_data_disks.*.id, count.index)}"
  # virtual_machine_id = "${element(azurerm_virtual_machine.compute.*.id, count.index)}"
  virtual_machine_id = "${element(concat(azurerm_virtual_machine.compute.*.id, azurerm_virtual_machine.compute_no_avset.*.id), count.index)}"
  lun                = "${count.index}"
  caching            = "None"
  # count = "${var.create_data_disk}"
  count                = "${var.compute_instance_count * var.create_data_disk}"

}
resource "azurerm_virtual_machine_extension" "vm_disk_mount" {
 count    = "${var.compute_instance_count * var.create_data_disk}"
 # count = "${var.compute_instance_count * var.create_data_disk * var.create_vm}"
 name = "vm_disk_mount"
 location = "${var.location}"
 resource_group_name = "${var.resource_group_name}"
 virtual_machine_name = "${element(concat(azurerm_virtual_machine.compute.*.name, azurerm_virtual_machine.compute_no_avset.*.name), count.index)}"
 publisher = "Microsoft.Azure.Extensions"
 type                 = "CustomScript"
 type_handler_version = "2.0"
 
 settings = <<SETTINGS
 {
 "commandToExecute": "sh OL_diskmount.sh ${var.admin_username}",
 "fileUris": ["https://scratchwasb.blob.core.windows.net/publiccontainer/OL_diskmount.sh"]
 }
 SETTINGS
}

# Networking
resource "azurerm_availability_set" "compute" {
  name                         = "${var.compute_hostname_prefix}-avset"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  tags                         = "${var.tags}"
}

resource "azurerm_network_interface" "compute" {
  count                         = "${var.compute_instance_count}"
  name                          = "${var.compute_hostname_prefix}-${format("%.02d",count.index + 1)}-nic"  
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
resource "azurerm_network_interface_backend_address_pool_association" "compute" {
  count                   = "${var.assign_bepool * var.compute_instance_count}"  
  network_interface_id     = "${element(concat(azurerm_network_interface.compute.*.id, azurerm_network_interface.compute_no_avset.*.id), count.index)}"
  ip_configuration_name   = "ipconfig${count.index}"
  backend_address_pool_id = "${var.backendpool_id}"
}

resource "azurerm_public_ip" "compute" {
  name                         = "${var.compute_hostname_prefix}-public-ip"
  count                        = "${var.create_public_ip}"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  allocation_method            = "${var.public_ip_address_allocation}"
  tags                         = "${var.tags}"
  sku                          = "${var.ip_sku}"
}
