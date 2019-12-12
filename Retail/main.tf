# retail/main.tf

locals {
    subnet_bits = 8   # want 256 entries per subnet.
    # determine difference between VNET CIDR bits and that size subnetBits.
    vnet_cidr_increase = "${32 - element(split("/",var.vnet_cidr),1) - local.subnet_bits}"
    subnetPrefixes = {
        application     = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 1)}"
        bastion-ftp     = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 2)}"
        identity        = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 3)}"
        AppGWSubnet   = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 9)}"
    }

    vnet_name = "${var.vnet_cidr == "0" ? 
    element(concat(data.azurerm_virtual_network.primary_vnet.*.name, list("")), 0) :
    element(concat(azurerm_virtual_network.primary_vnet.*.name, list("")), 0)}"
 
    vnet_cidr = "${var.vnet_cidr == "0" ? element(concat(data.azurerm_virtual_network.primary_vnet.*.address_space, list("")), 0) : var.vnet_cidr}"
    #####################
    ## NSGs

    bastion_sr_inbound = [
        {   # SSH from outside
            source_port_ranges = "*" 
#TODO: Note that only one of prefix or prefixes is allowed and keywords can't be in the list.
            source_address_prefix = "Internet"
            destination_port_ranges =  "22" 
        },{ # SSH from within any of the servers
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
            source_address_prefix = "${local.subnetPrefixes["bastion-ftp"]}"              
            destination_port_ranges = "22" 
            destination_address_prefix = "*"             
        },
        
     ]

    application_sr_outbound = [

        #TODO:
        # outbound to file service
    ]

        identity_sr_inbound = [
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["bastion-ftp"]}"              
            destination_port_ranges = "22" 
            destination_address_prefix = "*"             
        },
        {
            source_port_ranges =  "*" 
            source_address_prefix = "*"              
            destination_port_ranges = "80"
            destination_address_prefix = "*"           
        },
        
        {
            source_port_ranges =  "*" 
            source_address_prefix = "*"            
            destination_port_ranges = "443"
            destination_address_prefix = "*"              
        }
    ]

     identity_sr_outbound = [
        {  # SSH to any of the servers
            source_port_ranges =  "*" 
            source_address_prefix =  "${local.subnetPrefixes["identity"]}"     
            destination_port_ranges =  "1521" 
            destination_address_prefix = "192.168.10.0"      
        }
    ]

    ##########################################
    ## VMs in these subnets will need Availability sets.
    ##########################################
  #  needAVSets = [ "presentation", "application" ]
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
# Create the virtual network

data "azurerm_virtual_network" "primary_vnet" {
    name = "${var.vnet_name}"
    resource_group_name = "${var.vnet_resource_group_name}"
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

#################################################
# Setting up a private DNS Zone & A-records for OCI DNS resolution
 
resource "azurerm_dns_zone" "oci_vcn_dns" {
 name = "${var.oci_vcn_name}.oraclevcn.com"
 resource_group_name = "${azurerm_resource_group.rg.name}"
}
 
# Setting up A-records for the DB
 
resource "azurerm_dns_a_record" "db_a_record" {
 name = "${var.db_name}-scan.${var.oci_subnet_name}"
 resource_group_name = "${azurerm_resource_group.rg.name}"
 zone_name = "${azurerm_dns_zone.oci_vcn_dns.name}"
 ttl = 3600
 records = ["${var.db_scan_ip_addresses}"]
}



###############################################################
# Create each of the Network Security Groups
###############################################################

module "create_networkSGsForBastion" {
    source = "./modules/network/nsgWithRules"

    nsg_name            = "${azurerm_virtual_network.primary_vnet.name}-nsg-bastionftp"
    resource_group_name = "${azurerm_resource_group.vnet_rg.name}"
    location            = "${var.location}"
    tags                = "${var.tags}"    
    subnet_id           = "${module.create_subnets.subnet_names["bastion-ftp"]}"
    inboundOverrides    = "${local.bastion_sr_inbound}"
    outboundOverrides   = "${local.bastion_sr_outbound}"
}

module "create_networkSGsForApplication" {
    source = "./modules/network/nsgWithRules"

    nsg_name = "${azurerm_virtual_network.primary_vnet.name}-nsg-application"    
    resource_group_name = "${azurerm_resource_group.vnet_rg.name}"
    location = "${var.location}"
    tags = "${var.tags}"    
    subnet_id = "${module.create_subnets.subnet_names["application"]}"
    inboundOverrides  = "${local.application_sr_inbound}"
    outboundOverrides = "${local.application_sr_outbound}"
}

module "create_networkSGsForIdentity" {
    source = "./modules/network/nsgWithRules"

    nsg_name            = "${azurerm_virtual_network.primary_vnet.name}-nsg-identity"    
    resource_group_name = "${azurerm_resource_group.vnet_rg.name}"
    location            = "${var.location}"
    tags                = "${var.tags}"
    subnet_id           = "${module.create_subnets.subnet_names["identity"]}"
    inboundOverrides    = "${local.identity_sr_inbound}"
    outboundOverrides   = "${local.identity_sr_outbound}"
}


locals {
    # map of subnets which are to have NSGs attached.
    nsg_ids = {  
        # Note: if you change the number of subnets in this map, be sure to
        #       also adjust nsg_ids_len value (below) as well to the new number
        #       of entries.   The value of nsg_ids_len should be calculated 
        #       dynamically (e.g., "${length(local.nsg_ids)}"), but terraform then 
        #       refuses to allow it to be used as a count later.  Thus it is
        #       "hard-coded" below.   TF 0.12 can work around this, but not 0.11.
        bastion-ftp = "${module.create_networkSGsForBastion.nsg_id}"
        application = "${module.create_networkSGsForApplication.nsg_id}"
        identity    = "${module.create_networkSGsForIdentity.nsg_id}"
    }
    # Number of entries in nsg_ids. Can't be calculated. See note above.
    nsg_ids_len = 3
}
############################################################################################
# Create each of the subnets

module "create_subnets" {
    source = "./modules/network/subnets"

    subnet_cidr_map = "${local.subnetPrefixes}"
    resource_group_name = "${azurerm_resource_group.vnet_rg.name}"
    vnet_name = "${azurerm_virtual_network.primary_vnet.name}"
    nsg_ids = "${local.nsg_ids}"
    nsg_ids_len = "${local.nsg_ids_len}"  # Note: terraform has to have this for count later.
}


####################
# Create Boot Diag Storage Account

module "create_boot_sa" {
  source  = "./modules/storage"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix   = "retail-diag"
}



###################################################
# Create bastion host

module "create_bastion" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix   = "bastion"
  compute_instance_count    = "1"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  os_volume_size_in_gb      = "${var.os_volume_size_in_gb}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.compute_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["bastion-ftp"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  create_public_ip          = true
  create_data_disk          = false
  assign_bepool             = false
 
  
}

###################################################
# Create S-FTP Server

module "create_ftp" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix   = "sftp"
  compute_instance_count    = "${var.compute_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  os_volume_size_in_gb      = "${var.os_volume_size_in_gb}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.compute_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["bastion-ftp"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  create_public_ip          = false
  create_data_disk          = false
  assign_bepool             = false
}



###################################################
# Create Merch server
module "create_app" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix   = "app"
  compute_instance_count    = "${var.compute_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  os_volume_size_in_gb      = "${var.os_volume_size_in_gb}"
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.compute_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["application"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  backendpool_id            = "${module.create_BackendPools_app.backendpool_id}"
  create_public_ip          = false
  create_data_disk          = true
  assign_bepool             = true

 
}
###################################################
# Create IDM server
module "create_idm" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix   = "idm"
  compute_instance_count    = "${var.compute_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  os_volume_size_in_gb      = "${var.os_volume_size_in_gb}"
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.compute_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["application"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  backendpool_id            = "${module.create_BackendPools_idm.backendpool_id}"
  create_public_ip          = false
  create_data_disk          = true
  assign_bepool             = true 
}

###################################################
# Create Integration server
module "create_integ" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix   = "integ"
  compute_instance_count    = "${var.compute_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  os_volume_size_in_gb      = "${var.os_volume_size_in_gb}"
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.compute_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["application"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  backendpool_id            = "${module.create_BackendPools_integ.backendpool_id}"
  create_public_ip          = false
  create_data_disk          = true
  assign_bepool             = true
 }


###################################################
# Create RIA server
module "create_RIA" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix   = "ria"
  compute_instance_count    = "${var.compute_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  os_volume_size_in_gb      = "${var.os_volume_size_in_gb}"
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.compute_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["application"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  backendpool_id            = "${module.create_BackendPools_ria.backendpool_id}"
  create_public_ip          = false
  create_data_disk          = true
  assign_bepool             = true

 
}

module "create_identity" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix  = "id"
  compute_instance_count    = "${var.compute_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  os_volume_size_in_gb      = "${var.os_volume_size_in_gb}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.compute_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["identity"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  create_public_ip          = false
  assign_bepool             = false
  create_data_disk          = false
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
}



###################################################
# Create Internal Load Balancers


resource "azurerm_lb" "inlb" {
  name                = "${var.prefix}-lb"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  tags                = "${var.tags}"
  sku                 = "${var.lb_sku}"

  frontend_ip_configuration {
    name                          = "${var.frontend_name}-app"
    private_ip_address_allocation = "dynamic"
    subnet_id                 = "${module.create_subnets.subnet_ids["application"]}"

  }

    frontend_ip_configuration {
    name                          = "${var.frontend_name}-idm"
    private_ip_address_allocation = "dynamic"
    subnet_id                 = "${module.create_subnets.subnet_ids["application"]}"

  }

    frontend_ip_configuration {
    name                          = "${var.frontend_name}-integ"
    private_ip_address_allocation = "dynamic"
    subnet_id                 = "${module.create_subnets.subnet_ids["application"]}"

  }

    frontend_ip_configuration {
    name                          = "${var.frontend_name}-ria"
    private_ip_address_allocation = "dynamic"
    subnet_id                 = "${module.create_subnets.subnet_ids["application"]}"

  }

}

############################################################
# Create Internal LB Backend Pools with Rules

module "create_BackendPools_app" {
  source = "./modules/network/lbPoolsWithrules"

    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.location}"
    tags                = "${var.tags}"  
    frontend_subnet_id  = "${module.create_subnets.subnet_ids["application"]}"
    loadbalancer_id     = "${azurerm_lb.inlb.id}" 
    frontend_name_app   = "${var.frontend_name}-app"
    backendpool_name    = "BEpool_app"
    lb_port             = {
        apphttp = ["80", "Tcp", "80"]
   }
}

module "create_BackendPools_ria" {
  source = "./modules/network/lbPoolsWithrules"

    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.location}"
    tags                = "${var.tags}" 
    frontend_subnet_id  = "${module.create_subnets.subnet_ids["application"]}"   
    loadbalancer_id     = "${azurerm_lb.inlb.id}" 
    frontend_name_app   = "${var.frontend_name}-ria"
    backendpool_name    = "BEpool_ria"
    lb_port             = {
        riahttp = ["80", "Tcp", "80"]
  }
}

module "create_BackendPools_idm" {
  source = "./modules/network/lbPoolsWithrules"

    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.location}"
    tags                = "${var.tags}" 
    frontend_subnet_id  = "${module.create_subnets.subnet_ids["application"]}"   
    loadbalancer_id     = "${azurerm_lb.inlb.id}" 
    frontend_name_app   = "${var.frontend_name}-idm"
    backendpool_name    = "BEpool_idm"
    lb_port             = {
        idmhttp = ["80", "Tcp", "80"]
        custom = ["5575", "Tcp", "5575"]
        ldap = ["389", "tcp", "389"]
  }
}

module "create_BackendPools_integ" {
  source = "./modules/network/lbPoolsWithrules"

    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.location}"
    tags                = "${var.tags}" 
    frontend_subnet_id  = "${module.create_subnets.subnet_ids["application"]}"   
    loadbalancer_id     = "${azurerm_lb.inlb.id}" 
    frontend_name_app   = "${var.frontend_name}-integ"
    backendpool_name    = "BEpool_integ"
    lb_port             = {
        http = ["80", "Tcp", "80"]
  }
}



############################################################
# Create Application Gateway

module "create_app_gateway" {
  source = "./modules/app_gateway"

  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  prefix              = "appgw"
  frontend_subnet_id  = "${module.create_subnets.subnet_ids["AppGWSubnet"]}"
  vnet_name           = "${azurerm_virtual_network.primary_vnet.name}"
  lb_frontend_ips        = "${azurerm_lb.inlb.private_ip_addresses}"

 
}