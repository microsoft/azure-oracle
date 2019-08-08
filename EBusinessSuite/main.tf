locals {
    subnet_bits = 4   # 2^4 = 16 entries per subnet.
    # determine difference between VNET CIDR bits and that size subnetBits.
    vnet_cidr_increase = "${32 - element(split("/",local.vnet_cidr),1) - local.subnet_bits}"
    subnetPrefixes = {
        application     = "${cidrsubnet(local.vnet_cidr, local.vnet_cidr_increase, 1)}"
        database        = "${cidrsubnet(local.vnet_cidr, local.vnet_cidr_increase, 2)}"
        bastion         = "${cidrsubnet(local.vnet_cidr, local.vnet_cidr_increase, 3)}"
        identity        = "${cidrsubnet(local.vnet_cidr, local.vnet_cidr_increase, 4)}"
    }

    #####################
    ## NSGs

    bastion_sr_inbound = [
        {   # SSH from outside
            source_port_ranges = "*" 
            source_address_prefix = "Internet"
            destination_port_ranges =  "22" 
        },
        { # SSH from within any of the servers
            source_port_ranges =  "*" 
            source_address_prefix = "VirtualNetwork"
            destination_port_ranges =  "22" 
        } 
    ]

    bastion_sr_outbound = [
        {  # SSH to any of the servers
            source_port_ranges =  "*" 
            source_address_prefix = "VirtualNetwork"
            destination_port_ranges =  "22" 
        }    
    ]

    application_sr_inbound = [
        {
            source_port_ranges =  "*" 
            source_address_prefix = "AzureLoadBalancer"  # input from the Load Balancer only.             
            destination_port_ranges = "8000" 
            destination_address_prefix = "*"             
        },
        {   #TODO: Likely only one of 8000 or 8888 needed..
            source_port_ranges =  "*" 
            source_address_prefix = "AzureLoadBalancer"  # input from the Load Balancer only.             
            destination_port_ranges = "8888" 
            destination_address_prefix = "*"             
        },
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["bastion"]}"  # input from the Load Balancer only.               
            destination_port_ranges = "22" 
            destination_address_prefix = "*"             
        }
    ]

    application_sr_outbound = [
        {
            source_port_ranges =  "*" 
            source_address_prefix = "*" 
            destination_port_ranges =  "1521"            
            destination_address_prefix = "${var.database_in_azure ? local.subnetPrefixes["database"] : "*"}"  # out to DB
        }
        #TODO:
        # outbound to file service
    ]

    database_sr_inbound = [
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["application"]}"                 
            destination_port_ranges =  "1521" 
            destination_address_prefix = "*"             
        },
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["bastion"]}"  # input from the Load Balancer only.            
            destination_port_ranges =  "22" 
            destination_address_prefix = "*"                
        }
    ]
    database_sr_outbound = [
    ]

    identity_sr_inbound = [
        # TODO: Need Inbound and outbound ports and IPs to whitelist
    ]

    identity_sr_outbound = [
    ]

  vnet_name = "${var.vnet_cidr == "0" ? 
    element(concat(data.azurerm_virtual_network.primary_vnet.*.name, list("")), 0) :
    element(concat(azurerm_virtual_network.primary_vnet.*.name, list("")), 0)}"

  vnet_cidr = "${var.vnet_cidr == "0" ? element(data.azurerm_virtual_network.primary_vnet.address_space, 0) : var.vnet_cidr}"
}

############################################################################################
# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
  tags     = "${var.tags}"      #TODO: Add Tags to ebs_input.json   
}

resource "azurerm_resource_group" "vnet_rg" {
    name = "${var.vnet_resource_group_name}"
    location = "${var.location}"
    tags = "${var.tags}"
}

############################################################################################
# Check if a VNET exists, else create the virtual network
data "azurerm_virtual_network" "primary_vnet" {
    name = "${var.vnet_name}"
    resource_group_name = "${var.vnet_resource_group_name}"
    count = "${var.vnet_cidr == "0" ? 1 : 0}"
}

resource "azurerm_virtual_network" "primary_vnet" {
  name                = "${var.vnet_name}"
  resource_group_name = "${var.vnet_resource_group_name}"
  location            = "${var.location}"
  tags                = "${var.tags}"
  address_space       = ["${local.vnet_cidr}"]
  count = "${var.vnet_cidr != "0" ? 1 : 0}"
}

###############################################################
# Create Subnets & Network Security Groups
###############################################################
module "create_networkSGsForBastion" {
    source = "./modules/network/nsgWithRules"

    tier_name           = "bastion"
    vnet_name           = "${local.vnet_name}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    vnet_rg_name        = "${azurerm_resource_group.vnet_rg.name}"
    location            = "${var.location}"
    tags                = "${var.tags}"
    address_prefix      = "${lookup(local.subnetPrefixes, "bastion")}"
    inboundOverrides    = "${local.bastion_sr_inbound}"
    outboundOverrides   = "${local.bastion_sr_outbound}"
    createSubnetAndNSG  = true
}

module "create_networkSGsForApplication" {
    source = "./modules/network/nsgWithRules"

    tier_name           = "application"
    vnet_name           = "${local.vnet_name}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    vnet_rg_name        = "${azurerm_resource_group.vnet_rg.name}"
    location            = "${var.location}"
    tags                = "${var.tags}"    
    address_prefix      = "${lookup(local.subnetPrefixes, "application")}"
    inboundOverrides    = "${local.application_sr_inbound}"
    outboundOverrides   = "${local.application_sr_outbound}"
    createSubnetAndNSG  = true
}

module "create_networkSGsForDatabase" {
    source = "./modules/network/nsgWithRules"

    tier_name           = "database"
    vnet_name           = "${local.vnet_name}"  
    resource_group_name = "${azurerm_resource_group.rg.name}"
    vnet_rg_name        = "${azurerm_resource_group.vnet_rg.name}"
    location            = "${var.location}"
    tags                = "${var.tags}"
    address_prefix      = "${lookup(local.subnetPrefixes, "database")}"
    inboundOverrides    = "${local.database_sr_inbound}"
    outboundOverrides   = "${local.database_sr_outbound}"
    createSubnetAndNSG  = "${var.database_in_azure}"
}

module "create_networkSGsForIdentity" {
    source = "./modules/network/nsgWithRules"
    
    tier_name           = "identity"
    vnet_name           = "${local.vnet_name}"  
    resource_group_name = "${azurerm_resource_group.rg.name}"
    vnet_rg_name        = "${azurerm_resource_group.vnet_rg.name}"
    location            = "${var.location}"
    tags                = "${var.tags}"
    address_prefix      = "${lookup(local.subnetPrefixes, "identity")}"
    inboundOverrides    = "${local.identity_sr_inbound}"
    outboundOverrides   = "${local.identity_sr_outbound}"
    createSubnetAndNSG  = true                              #TODO: Setup Bool variable for identity setup
}

###################################################
# Create a Storage account ofr Boot diagnostics 
# information for all VMs.

resource "random_id" "vm-sa" {
  keepers = {
      tmp = "${var.vm_hostname_prefix_app}"
  }
  byte_length = 8
}

resource "azurerm_storage_account" "vm-sa" {
  name                     = "bootdiag${lower(random_id.vm-sa.hex)}"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${var.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = "${var.tags}"
}


###################################################
# Create bastion host

module "create_bastion" {
  source  = "./modules/compute"

  resource_group_name               = "${azurerm_resource_group.rg.name}"
  location                          = "${var.location}"
  tags                              = "${var.tags}"
  compute_hostname_prefix           = "${var.vm_hostname_prefix_bastion}"
  instance_count                    = "${var.bastion_instance_count}"
  vm_size                           = "${var.vm_size}"
  os_publisher                      = "${var.os_publisher}"   
  os_offer                          = "${var.os_offer}"
  os_sku                            = "${var.os_sku}"
  os_version                        = "${var.os_version}"
  storage_account_type              = "${var.storage_account_type}"
  boot_volume_size_in_gb            = "${var.bastion_boot_volume_size_in_gb}"
  admin_username                    = "${var.admin_username}"
  custom_data                       = "${var.custom_data}"
  ssh_public_key                    = "${var.bastion_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id                    = "${module.create_networkSGsForBastion.subnet_id}"
  boot_diag_SA_endpoint             = "${azurerm_storage_account.vm-sa.primary_blob_endpoint}"
  assign_public_ip                  = true
  public_ip_address_allocation      = "Static"
  public_ip_sku                     = "Standard"
  attach_data_disks                 = false
  data_sa_type                      = "null"
  data_disk_size_gb                 = 0
}

###################################################
# Create Application server
module "create_app" {
  source  = "./modules/compute"

  resource_group_name           = "${azurerm_resource_group.rg.name}"
  location                      = "${var.location}"
  tags                          = "${var.tags}"
  compute_hostname_prefix       = "${var.vm_hostname_prefix_app}"
  instance_count                = "${var.app_instance_count}"
  vm_size                       = "${var.vm_size}"
  os_publisher                  = "${var.os_publisher}"   
  os_offer                      = "${var.os_offer}"
  os_sku                        = "${var.os_sku}"
  os_version                    = "${var.os_version}"
  storage_account_type          = "${var.storage_account_type}"
  boot_volume_size_in_gb        = "${var.compute_boot_volume_size_in_gb}"
  attach_data_disks             = true
  data_disk_size_gb             = "${var.data_disk_size_gb}"
  data_sa_type                  = "${var.data_sa_type}"
  admin_username                = "${var.admin_username}"
#  admin_password            = "${var.admin_password}"
  custom_data                   = "${var.custom_data}"
  ssh_public_key                = "${var.compute_ssh_public_key}"
  enable_accelerated_networking = "${var.enable_accelerated_networking}"
  vnet_subnet_id                = "${module.create_networkSGsForApplication.subnet_id}"
  boot_diag_SA_endpoint         = "${azurerm_storage_account.vm-sa.primary_blob_endpoint}"
  assign_public_ip              = false
  public_ip_address_allocation  = "Static"
  public_ip_sku                 = "Standard"
}

###################################################
# Create Identity server
module "create_identity" {
  source  = "./modules/compute"

  resource_group_name           = "${azurerm_resource_group.rg.name}"
  location                      = "${var.location}"
  tags                          = "${var.tags}"
  compute_hostname_prefix       = "${var.vm_hostman_prefix_identity}"
  instance_count                = "${var.identity_instance_count}"
  vm_size                       = "${var.vm_size}"
  os_publisher                  = "${var.os_publisher}"   
  os_offer                      = "${var.os_offer}"
  os_sku                        = "${var.os_sku}"
  os_version                    = "${var.os_version}"
  storage_account_type          = "${var.storage_account_type}"
  boot_volume_size_in_gb        = "${var.compute_boot_volume_size_in_gb}"
  attach_data_disks             = false
  data_disk_size_gb             = "${var.data_disk_size_gb}"
  data_sa_type                  = "${var.data_sa_type}"
  admin_username                = "${var.admin_username}"
#  admin_password               = "${var.admin_password}"
  custom_data                   = "${var.custom_data}"
  ssh_public_key                = "${var.compute_ssh_public_key}"
  enable_accelerated_networking = "${var.enable_accelerated_networking}"
  vnet_subnet_id                = "${module.create_networkSGsForIdentity.subnet_id}"
  boot_diag_SA_endpoint         = "${azurerm_storage_account.vm-sa.primary_blob_endpoint}"
  assign_public_ip              = true
  public_ip_address_allocation  = "Static"
  public_ip_sku                 = "Standard"
}

###################################################
# Create Load Balancer for App Tier
module "lb" {
  source = "./modules/load_balancer"

  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  tags                = "${var.tags}"  
  prefix              = "${var.vm_hostname_prefix_app}"
  lb_sku              = "${var.lb_sku}"
  frontend_subnet_id  = "${module.create_networkSGsForApplication.subnet_id}"
  lb_port             = {
        http = ["8080", "Tcp", "8888"]
  }
} 

resource "azurerm_network_interface_backend_address_pool_association" "compute" {
  network_interface_id    = "${element(module.create_app.vm_nics, count.index)}"
  ip_configuration_name   = "ipconfig${count.index}"
  backend_address_pool_id = "${module.lb.backendpool_id}"
  count                   = "${var.app_instance_count}" 
}

###################################################
# Create Load Balancer for Identity Tier
module "identity_lb" {
  source = "./modules/load_balancer"

  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  tags                = "${var.tags}"  
  prefix              = "${var.vm_hostman_prefix_identity}"
  lb_sku              = "${var.lb_sku}"
  frontend_subnet_id  = "${module.create_networkSGsForIdentity.subnet_id}"
  lb_port             = {
        http = ["8080", "Tcp", "8888"]
  }
} 

resource "azurerm_network_interface_backend_address_pool_association" "identity_pool" {
  network_interface_id    = "${element(module.create_identity.vm_nics, count.index)}"
  ip_configuration_name   = "ipconfig${count.index}"
  backend_address_pool_id = "${module.identity_lb.backendpool_id}"
  count = "${var.identity_instance_count}" 
}