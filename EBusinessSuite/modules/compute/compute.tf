locals {
  availability_zones_list = ["East US", "eastus", "East US 2", "eastus2", "Central US", "centralus", "West US 2", "westus2", "North Europe", "northeurope", "UK South", "uksouth", "West Europe", "westeurope", "France Central", "francecentral", "Japan East", "japaneast", "Southeast Asia", "southeastasia"]
  useZones = "${contains(local.availability_zones_list, var.location) == true ? 1 : 0}"
}


#  Provision Application VMs
resource "azurerm_virtual_machine" "compute-az" {
  count                         = "${var.instance_count * local.useZones * var.create_vm}"
  name                          = "${var.compute_hostname_prefix}-${format("%.02d",count.index + 1)}"
  location                      = "${var.location}"
  resource_group_name           = "${var.resource_group_name}"
  vm_size                       = "${var.vm_size}"
  network_interface_ids         = ["${element(concat(azurerm_network_interface.nic.*.id, azurerm_network_interface.public_nic.*.id), count.index)}"]
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
    disk_size_gb      = "${var.boot_volume_size_in_gb}"
    managed_disk_type = "${var.storage_account_type}"
  }

/*  storage_data_disk {
    name              = "${var.compute_hostname_prefix}-${format("%.02d",count.index + 1)}-disk-data-01"    
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "${var.data_disk_size_gb}"
    managed_disk_type = "${var.storage_account_type}"
  } */

  os_profile {
    computer_name  = "${var.compute_hostname_prefix}-${format("%.02d",count.index + 1)}"
    admin_username = "${var.admin_username}"
  #  admin_password = "${var.admin_password}"
    custom_data    = "${var.custom_data}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${file("${var.ssh_public_key}")}"
    }
  }

  tags = "${var.tags}"
  zones = ["${contains(local.availability_zones_list, var.location) == true ? (count.index % 3) + 1 : 1}"]

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${var.boot_diag_SA_endpoint}"
  }

}

resource "azurerm_virtual_machine" "compute-as" {
  count                         = "${var.instance_count * (1 - local.useZones) * var.create_vm}"
  name                          = "${var.compute_hostname_prefix}-${format("%.02d",count.index + 1)}"
  location                      = "${var.location}"
  resource_group_name           = "${var.resource_group_name}"
  availability_set_id           = "${element(concat(azurerm_availability_set.compute.*.id, list("0")), 0)}"
  vm_size                       = "${var.vm_size}"
  network_interface_ids         = ["${element(concat(azurerm_network_interface.nic.*.id, azurerm_network_interface.public_nic.*.id), count.index)}"]
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
    disk_size_gb      = "${var.boot_volume_size_in_gb}"
    managed_disk_type = "${var.storage_account_type}"
  }

/*  storage_data_disk {
    name              = "${var.compute_hostname_prefix}-${format("%.02d",count.index + 1)}-disk-data-01"    
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "${var.data_disk_size_gb}"
    managed_disk_type = "${var.storage_account_type}"
  } */

  os_profile {
    computer_name  = "${var.compute_hostname_prefix}-${format("%.02d",count.index + 1)}"
    admin_username = "${var.admin_username}"
  #  admin_password = "${var.admin_password}"
    custom_data    = "${var.custom_data}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${file("${var.ssh_public_key}")}" #TODO: Pass private key file onto bastion
    }
  }

  tags = "${var.tags}"

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${var.boot_diag_SA_endpoint}"
  }
}

resource "azurerm_availability_set" "compute" {
  name                         = "${var.compute_hostname_prefix}-avset"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  tags                         = "${var.tags}"
  count                        = "${(1 - local.useZones) * var.create_vm}"
}

resource "azurerm_network_interface" "nic" {
#  count                         = "${var.instance_count}"
  count                         = "${(1 - var.assign_public_ip) * var.instance_count * var.create_vm}"
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


resource "azurerm_network_interface" "public_nic" {
 count                         = "${var.assign_public_ip * var.instance_count * var.create_vm}"
  name                          = "${var.compute_hostname_prefix}-${format("%.02d",count.index + 1)}-nic"  
  location                      = "${var.location}"
  resource_group_name           = "${var.resource_group_name}"
  enable_accelerated_networking = "${var.enable_accelerated_networking}"

  ip_configuration {
    name                          = "ipconfig${count.index}"
    subnet_id                     = "${var.vnet_subnet_id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.public_ip.*.id, count.index)}"
  }

  tags = "${var.tags}"
} 

resource "azurerm_public_ip" "public_ip" {
  name                         = "${var.compute_hostname_prefix}-${format("%.02d",count.index + 1)}-public-ip"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  allocation_method            = "${var.public_ip_address_allocation}"
  tags                         = "${var.tags}"
  sku                          = "${var.public_ip_sku}"
  count                        = "${var.assign_public_ip * var.instance_count * var.create_vm}"     #Terraform's version of If-Else Statement
}

/*
resource "azurerm_network_interface_backend_address_pool_association" "compute" {
  network_interface_id    = "${element(concat(azurerm_network_interface.nic.*.id, azurerm_network_interface.public_nic.*.id), count.index)}"
  ip_configuration_name   = "ipconfig${count.index}"
  backend_address_pool_id = "${var.backendpool_id}"
  count = "${var.backendpool_id == "null" ? 0 : var.instance_count}"    //START HERE -> Fix this. Consider moving this to main.tf or to LoadBalancer module and add output for the two NICs
} */

resource "azurerm_managed_disk" "vm_data_disks-az" {
    name                 = "${var.compute_hostname_prefix}-${format("%.02d",count.index + 1)}-data-disk"
    location             = "${var.location}"
    resource_group_name  = "${var.resource_group_name}"
    storage_account_type = "${var.storage_account_type}"
    create_option        = "Empty"
    disk_size_gb         = "${var.data_disk_size_gb}"
    count                = "${var.instance_count * var.attach_data_disks * local.useZones * var.create_vm}"
    zones                = ["${contains(local.availability_zones_list, var.location) == true ? (count.index % 3) + 1 : 1}"]
    tags                 = "${var.tags}"
}

resource "azurerm_managed_disk" "vm_data_disks-as" {
    name                 = "${var.compute_hostname_prefix}-${format("%.02d",count.index + 1)}-data-disk"
    location             = "${var.location}"
    resource_group_name  = "${var.resource_group_name}"
    storage_account_type = "${var.storage_account_type}"
    create_option        = "Empty"
    disk_size_gb         = "${var.data_disk_size_gb}"
    count = "${var.instance_count * var.attach_data_disks * (1 - local.useZones) * var.create_vm}"
  #  count = "${var.num_of_vm_data_disks}"
    tags                 = "${var.tags}"
}

resource "azurerm_virtual_machine_data_disk_attachment" "vm_data_disks_attachment" {
  managed_disk_id    = "${element(concat(azurerm_managed_disk.vm_data_disks-as.*.id, azurerm_managed_disk.vm_data_disks-az.*.id), count.index)}"
  virtual_machine_id = "${element(concat(azurerm_virtual_machine.compute-as.*.id, azurerm_virtual_machine.compute-az.*.id), count.index)}"
  lun                = "${count.index}"
  caching            = "None"
  count = "${var.instance_count * var.attach_data_disks * var.create_vm}"
}

resource "azurerm_virtual_machine_extension" "vm_disk_mount" {
  count = "${var.instance_count * var.attach_data_disks * var.create_vm}"
  name = "vm_disk_mount"
  location = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  virtual_machine_name = "${element(concat(azurerm_virtual_machine.compute-as.*.name, azurerm_virtual_machine.compute-az.*.name), count.index)}"
  publisher = "Microsoft.Azure.Extensions"
  type = "CustomScript"
  type_handler_version = "2.0"
  
  settings = <<SETTINGS
  {
    "commandToExecute": "sh OL_diskmount.sh ${var.admin_username}",
    "fileUris": ["https://scratchwasb.blob.core.windows.net/publiccontainer/OL_diskmount.sh"]
  }
  SETTINGS
}