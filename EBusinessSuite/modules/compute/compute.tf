/*Copyright © 2018, Oracle and/or its affiliates. All rights reserved.

The Universal Permissive License (UPL), Version 1.0*/

/* 
resource "oci_core_instance" "compute" {
  count               = "${var.compute_instance_count}"
  availability_domain = "${element(var.availability_domain, count.index)}"
  display_name        = "${var.compute_hostname_prefix}${element(var.AD,count.index)}${count.index + 1}"
  fault_domain        = "${element(var.fault_domain, count.index)}"
  compartment_id      = "${var.compartment_ocid}" 
  shape               = "${var.compute_instance_shape}"
    
  create_vnic_details {
    subnet_id         = "${element(var.compute_subnet, count.index)}"
    display_name      = "${var.compute_hostname_prefix}${element(var.AD,count.index)}${count.index + 1}"
    assign_public_ip  = false
    hostname_label    = "${var.compute_hostname_prefix}${element(var.AD,count.index)}${count.index + 1}"
  },
  
  source_details {
    source_type             = "image"
    source_id               = "${var.compute_image}"
    boot_volume_size_in_gbs = "${var.compute_boot_volume_size_in_gb}"
  }
  
  metadata {
    ssh_authorized_keys = "${trimspace(file("${var.compute_ssh_public_key}"))}"
    user_data           = "${base64encode(data.template_file.bootstrap.rendered)}"
  }  
  
  timeouts {
    create = "${var.timeout}"
  }
}
  */

resource "random_id" "vm-sa" {
  keepers = {
    vm_hostname = "${var.vm_hostname}"
  }

  byte_length = 6
}

resource "azurerm_storage_account" "vm-sa" {
  name                     = "bootdiag${lower(random_id.vm-sa.hex)}"
  resource_group_name      = "${var.resource_group_name}"
  location                 = "${var.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = "${var.tags}"
}

resource "azurerm_virtual_machine" "compute" {
  name                          = "${var.compute_hostname_prefix}${count.index + 1}"
  count                         = "${var.compute_instance_count}"
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
    name              = "osdisk-${var.vm_hostname}-${count.index}"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    disk_size_gb      = "${var.compute_boot_volume_size_in_gb}"
    managed_disk_type = "${var.storage_account_type}"
  }

  storage_data_disk {
    name              = "datadisk-${var.vm_hostname}-${count.index}"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "${var.data_disk_size_gb}"
    managed_disk_type = "${var.data_sa_type}"
  }

  os_profile {
    computer_name  = "${var.vm_hostname}${count.index}"
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
    storage_uri = "${join(",", azurerm_storage_account.vm-sa.*.primary_blob_endpoint)}"
  }
}
resource "azurerm_availability_set" "compute" {
  name                         = "${var.vm_hostname}-avset"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  tags                         = "${var.tags}"
}

resource "azurerm_network_interface" "compute" {
  count                         = "${var.nb_instances}"
  name                          = "${var.compute_hostname_prefix}${count.index + 1}"
  location                      = "${var.location}"
  resource_group_name           = "${var.resource_group_name}"
  #TODO network_security_group_id     = "${var.network_security_group_id}"
  enable_accelerated_networking = "${var.enable_accelerated_networking}"

  ip_configuration {
    name                          = "ipconfig${count.index}"
    subnet_id                     = "${var.vnet_subnet_id}"
    private_ip_address_allocation = "Dynamic"
  }

  tags = "${var.tags}"
}