locals {
    total_data_disk_count = "${var.number_of_data_disks * var.instance_count}"
    total_redo_disk_count = "${var.number_of_redo_log_disks * var.instance_count}"
}

resource "azurerm_network_interface" "vm_nic_private" {
    name                      = "${var.nic_name}-${count.index}"
    location                  = "${var.location}"
    resource_group_name       = "${var.resource_group_name}"
    network_security_group_id = "${var.nsg_id}"

    ip_configuration {
        name                          = "${var.ip_config_name}-${count.index}"
        subnet_id                     = "${var.subnet_id}"
        private_ip_address_allocation = "dynamic"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "db_vm" {
    name                  = "${var.vm_name}-${count.index}"
    location              = "${var.location}"
    resource_group_name   = "${var.resource_group_name}"
    network_interface_ids = ["${element(azurerm_network_interface.vm_nic_private.*.id, count.index)}"]
    vm_size               = "${var.vm_size}"
    availability_set_id = "${var.availability_set_id}"
    delete_os_disk_on_termination = true    #TODO: Hard-coding for now
    

    storage_os_disk {
        name              = "${var.vm_name}-${count.index}-os"
        caching           = "ReadWrite"         #TODO: Hard-coding these values for now. Confirm with Oracle on what the preferred values are
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
        disk_size_gb = "${var.vm_os_disk_size_in_gb}"
    }

    storage_image_reference {
        publisher = "${var.os_publisher}"
        offer     = "${var.os_offer}"
        sku       = "${var.os_sku}"
        version   = "${var.os_version}"
    }

    os_profile {
        computer_name  = "${var.vm_name}-${count.index}"
        admin_username = "${var.vm_admin_username}"
        admin_password = "${var.vm_admin_password}"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    depends_on = ["azurerm_network_interface.vm_nic_private"]
    count = "${var.instance_count}"
}

resource "azurerm_managed_disk" "data_disks" {
    name                 = "${var.vm_name}-data-disk${count.index}"
    location             = "${var.location}"
    resource_group_name  = "${var.resource_group_name}"
    storage_account_type = "${var.data_disks_sku}"
    create_option        = "Empty"
    disk_size_gb         = "${var.size_of_data_disks_in_gb}"
    count = "${local.total_data_disk_count}"
}

resource "azurerm_managed_disk" "redo_logs_disks" {
    name                 = "${var.vm_name}-redo-disk${count.index}"
    location             = "${var.location}"
    resource_group_name  = "${var.resource_group_name}"
    storage_account_type = "${var.redo_log_disks_sku}"
    create_option        = "Empty"
    disk_size_gb         = "${var.size_of_redo_log_disks_in_gb}"
    count = "${var.number_of_redo_log_disks * var.instance_count}" 
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disks_attachment" {
  managed_disk_id    = "${element(azurerm_managed_disk.data_disks.*.id, count.index)}"
  virtual_machine_id = "${element(azurerm_virtual_machine.db_vm.*.id, floor(count.index / var.instance_count))}"
  lun                = "${floor(count.index / var.instance_count)}"
  caching            = "None"
  count = "${local.total_data_disk_count}"
}

resource "azurerm_virtual_machine_data_disk_attachment" "redo_disks_attachment" {
  managed_disk_id    = "${element(azurerm_managed_disk.redo_logs_disks.*.id, count.index)}"
  virtual_machine_id = "${element(azurerm_virtual_machine.db_vm.*.id, floor(count.index / var.instance_count))}"
  lun                = "${15 - floor(count.index / var.instance_count)}"                                //Max number of disks can be 16
  caching            = "None"
  count = "${local.total_redo_disk_count}"
}