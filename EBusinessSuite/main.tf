locals {
    # determine difference between VNET CIDR bits and that size subnetBits.
    vnet_cidr_increase = "${32 - element(split("/",local.vnet_cidr),1) - var.subnet_bits}"
    subnetPrefixes = {
        application     = "${cidrsubnet(local.vnet_cidr, local.vnet_cidr_increase, 1)}"
        bastion         = "${cidrsubnet(local.vnet_cidr, local.vnet_cidr_increase, 2)}"
        identity        = "${cidrsubnet(local.vnet_cidr, local.vnet_cidr_increase, 3)}"
    #    database        = "${cidrsubnet(local.vnet_cidr, local.vnet_cidr_increase, 4)}"
    }

    vm_hostname_prefix_app= "app",
    vm_hostname_prefix_identity= "ebs-asserter",
    vm_hostname_prefix_bastion= "bastion",
    bastion_instance_count = 1,
    bastion_boot_volume_size_in_gb = 128

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
            source_address_prefix = "${local.subnetPrefixes["bastion"]}"  # SSH from the Bastion host onlu.               
            destination_port_ranges = "22" 
            destination_address_prefix = "*"             
        }
    ]

    application_sr_outbound = [
        {
            source_port_ranges =  "*" 
            source_address_prefix = "*" 
            destination_port_ranges =  "1521"            
        #    destination_address_prefix = "${var.database_in_azure ? local.subnetPrefixes["database"] : "*"}"  # out to DB
            destination_address_prefix = "${var.oci_db_subnet_cidr}"
        }
    ]

/*    database_sr_inbound = [
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
    */

    identity_sr_inbound = [
        {
            source_port_ranges =  "*" 
            source_address_prefix = "Internet"                 
            destination_port_ranges =  "80" 
            destination_address_prefix = "*"             
        },
        {
            source_port_ranges =  "*" 
            source_address_prefix = "Internet"                 
            destination_port_ranges =  "443" 
            destination_address_prefix = "*"             
        },
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["bastion"]}"  # input from the Load Balancer only.            
            destination_port_ranges =  "22" 
            destination_address_prefix = "*"                
        }
    ]

    identity_sr_outbound = [
        {
            source_port_ranges =  "*" 
            source_address_prefix = "*" 
            destination_port_ranges =  "1521"            
        #    destination_address_prefix = "${var.database_in_azure ? local.subnetPrefixes["database"] : "*"}"  # out to DB
            destination_address_prefix = "${var.oci_db_subnet_cidr}"
        }
    ]

  vnet_name = "${var.vnet_cidr == "0" ? 
    element(concat(data.azurerm_virtual_network.primary_vnet.*.name, list("")), 0) :
    element(concat(azurerm_virtual_network.primary_vnet.*.name, list("")), 0)}"

  vnet_cidr = "${var.vnet_cidr == "0" ? element(concat(data.azurerm_virtual_network.primary_vnet.*.address_space, list("")), 0) : var.vnet_cidr}"
}

############################################################################################
# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
  tags     = "${var.tags}"
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
    resource_group_name = "${azurerm_resource_group.vnet_rg.name}"
    count = "${var.vnet_cidr == "0" ? 1 : 0}"
}

resource "azurerm_virtual_network" "primary_vnet" {
  name                = "${var.vnet_name}"
  resource_group_name = "${azurerm_resource_group.vnet_rg.name}"
  location            = "${var.location}"
  tags                = "${var.tags}"
  address_space       = ["${local.vnet_cidr}"]
  count = "${var.vnet_cidr != "0" ? 1 : 0}"
}

###############################################################
# Create Subnets & Network Security Groups
###############################################################

# GatewaySubnet must exist for the OCI interconnect
data "azurerm_subnet" "gateway_subnet" {
    name = "GatewaySubnet"
    virtual_network_name = "${local.vnet_name}"
    resource_group_name = "${var.vnet_resource_group_name}"
    count = "${var.vnet_cidr == "0" ? 1 : 0}"
}

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

/*
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
} */

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
    createSubnetAndNSG  = "${var.enable_identity_integration}"                             
}


###################################################
# Create a Storage account ofr Boot diagnostics 
# information for all VMs.

resource "random_id" "vm-sa" {
  keepers = {
      tmp = "${local.vm_hostname_prefix_app}"
  }
  byte_length = 8
}

resource "azurerm_storage_account" "vm-sa" {
  name                     = "bootdiag${lower(random_id.vm-sa.hex)}"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${var.location}"
  account_tier             = "${element(split("_", var.storage_account_type), 0)}"
  account_replication_type = "${element(split("_", var.storage_account_type), 1)}"
  tags                     = "${var.tags}"
}


###################################################
# Create bastion host

module "create_bastion" {
  source  = "./modules/compute"

  resource_group_name               = "${azurerm_resource_group.rg.name}"
  location                          = "${var.location}"
  tags                              = "${var.tags}"
  compute_hostname_prefix           = "${local.vm_hostname_prefix_bastion}"
  instance_count                    = "${local.bastion_instance_count}"
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
  data_disk_size_gb                 = 0
  create_vm                         = true
}

###################################################
# Create Application server
module "create_app" {
  source  = "./modules/compute"

  resource_group_name           = "${azurerm_resource_group.rg.name}"
  location                      = "${var.location}"
  tags                          = "${var.tags}"
  compute_hostname_prefix       = "${local.vm_hostname_prefix_app}"
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
  create_vm                     = true
}

###################################################
# Create Identity server
module "create_identity" {
  source  = "./modules/compute"

  resource_group_name           = "${azurerm_resource_group.rg.name}"
  location                      = "${var.location}"
  tags                          = "${var.tags}"
  compute_hostname_prefix       = "${local.vm_hostname_prefix_identity}"
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
  create_vm                     = "${var.enable_identity_integration}"      
}

###################################################
# Create Load Balancer for App Tier
module "lb" {
  source = "./modules/load_balancer"

  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  tags                = "${var.tags}"  
  prefix              = "${local.vm_hostname_prefix_app}"
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
  prefix              = "${local.vm_hostname_prefix_identity}"
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


#################################################
# Setting up a private DNS Zone & A-records for OCI DNS resolution
# TODO: Needs to be updated with the Private DNS Zone resource type once available

resource "azurerm_dns_zone" "oci_vcn_dns" {
  name                = "${var.oci_vcn_name}.oraclevcn.com"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  zone_type           = "Private"
  tags                = "${var.tags}"
}

# Setting up A-records for the DB

resource "azurerm_dns_a_record" "db_a_record" {
  name = "${var.db_name}-scan.${var.oci_subnet_name}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  zone_name = "${azurerm_dns_zone.oci_vcn_dns.name}"
  ttl = 3600
  records = "${var.db_scan_ip_addresses}"
}
