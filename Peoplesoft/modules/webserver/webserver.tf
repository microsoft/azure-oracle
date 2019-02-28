resource "random_id" "vm-sa" {
  keepers = {
      tmp = "${var.compute_hostname_prefix_web}"
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

resource "azurerm_virtual_machine" "webserver" {
  name                          = "${var.compute_hostname_prefix_web}-${format("%.02d",count.index + 1)}"
  count                         = "${var.webserver_instance_count}"
  location                      = "${var.location}"
  resource_group_name           = "${var.resource_group_name}"
  availability_set_id           = "${azurerm_availability_set.webserver.id}"
  vm_size                       = "${var.vm_size}"
  network_interface_ids         = ["${element(azurerm_network_interface.webserver.*.id, count.index)}"]
  delete_os_disk_on_termination = "true"

# Add cloud init
  storage_image_reference {
    publisher = "${var.os_publisher}"
    offer     = "${var.os_offer}"
    sku       = "${var.os_sku}"
    version   = "${var.os_version}"
}

  storage_os_disk {
    name              = "${var.compute_hostname_prefix_web}-${format("%.02d",count.index + 1)}-disk-OS"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    disk_size_gb      = "${var.webserver_boot_volume_size_in_gb}"
    managed_disk_type = "${var.storage_account_type}"
  }

  storage_data_disk {
    name              = "${var.compute_hostname_prefix_web}-${format("%.02d",count.index + 1)}-disk-data-01"    
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "${var.data_disk_size_gb}"
    managed_disk_type = "${var.data_sa_type}"
  }

  os_profile {
    computer_name  = "${var.compute_hostname_prefix_web}-${format("%.02d",count.index + 1)}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
    custom_data    = "${var.custom_data}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${file("${var.webserver_ssh_public_key}")}"
    }
  }

  tags = "${var.tags}"

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.vm-sa.primary_blob_endpoint}"
    # storage_uri = "${join(",", azurerm_storage_account.vm-sa.*.primary_blob_endpoint)}"}
  }
}

resource "azurerm_availability_set" "webserver" {
  name                         = "${var.compute_hostname_prefix_web}-avset"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  tags                         = "${var.tags}"
}

resource "azurerm_network_interface" "webserver" {
  count                         = "${var.webserver_instance_count}"
  name                          = "${var.compute_hostname_prefix_web}-${format("%.02d",count.index + 1)}-nic"  
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

resource "azurerm_network_interface_backend_address_pool_association" "webserver" {
  count                   = "${var.webserver_instance_count}"
  network_interface_id    = "${element(azurerm_network_interface.webserver.*.id, count.index)}"
  ip_configuration_name   = "ipconfig${count.index}"
  backend_address_pool_id = "${var.backendpool_id}"
}