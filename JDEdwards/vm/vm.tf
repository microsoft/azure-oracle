#Creating Public IP
resource "azurerm_public_ip" "vm_public_ip" {
    name                         = "${var.public_ip_name}-${count.index}"
    location                     = "${var.location}"
    resource_group_name          = "${var.resource_group_name}"
    allocation_method = "Static"
    count = "${var.assign_public_ip * var.instance_count}"           #Terraform's version of If-Else Statement
}

# Create network interface - with Public IP
resource "azurerm_network_interface" "vm_nic_public" {
    name                      = "${var.nic_name}-${count.index}"
    location                  = "${var.location}"
    resource_group_name       = "${var.resource_group_name}"
    network_security_group_id = "${var.nsg_id}"

    ip_configuration {
        name                          = "${var.ip_config_name}-${count.index}"
        subnet_id                     = "${var.subnet_id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.vm_public_ip.id}"
    }

    count = "${var.assign_public_ip * var.instance_count}"       #Terraform's version of If-Else Statement multipled by number of instance
    depends_on = ["azurerm_public_ip.vm_public_ip"]
}

# Create network interface - only Private IP
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

    count = "${(1 - var.assign_public_ip) * var.instance_count}"       #Terraform's version of If-Else Statement
}


# Create virtual machine
resource "azurerm_virtual_machine" "host_vm" {
    name                  = "${var.vm_name}-${count.index}"
    location              = "${var.location}"
    resource_group_name   = "${var.resource_group_name}"
    network_interface_ids = ["${element(concat(azurerm_network_interface.vm_nic_private.*.id, azurerm_network_interface.vm_nic_public.*.id), count.index)}"]
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

    #TODO: Do we need attached data disks?

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

    depends_on = ["azurerm_network_interface.vm_nic_private",
    "azurerm_network_interface.vm_nic_public",
    "azurerm_public_ip.vm_public_ip"]

    count = "${var.instance_count}"
}