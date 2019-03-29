# ebs/main.tf

locals {
    subnet_bits = 8   # want 256 entries per subnet.
    # determine difference between VNET CIDR bits and that size subnetBits.
    vnet_cidr_increase = "${32 - element(split("/",var.vnet_cidr),1) - local.subnet_bits}"
    subnetPrefixes = {
        application     = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 1)}"
        bastion-ftp     = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 2)}"
        # Note that ExpressRoute setup needs exactly "GatewaySubnet" as the gateway subnet name.
        GatewaySubnet   = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 9)}"
    }


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

############################################################################################
# Create the virtual network
module "create_vnet" {
    source = "./modules/network/vnet"

    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.location}"
    tags                = "${var.tags}"    
    vnet_cidr           = "${var.vnet_cidr}"
    vnet_name           = "${var.vnet_name}"
}

###############################################################
# Create each of the Network Security Groups
###############################################################

module "create_networkSGsForBastion" {
    source = "./modules/network/nsgWithRules"

    nsg_name            = "${module.create_vnet.vnet_name}-nsg-bastionftp"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.location}"
    tags                = "${var.tags}"    
    subnet_id           = "${module.create_subnets.subnet_names["bastion-ftp"]}"
    inboundOverrides    = "${local.bastion_sr_inbound}"
    outboundOverrides   = "${local.bastion_sr_outbound}"
}

module "create_networkSGsForApplication" {
    source = "./modules/network/nsgWithRules"

    nsg_name = "${module.create_vnet.vnet_name}-nsg-application"    
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location = "${var.location}"
    tags = "${var.tags}"    
    subnet_id = "${module.create_subnets.subnet_names["application"]}"
    inboundOverrides  = "${local.application_sr_inbound}"
    outboundOverrides = "${local.application_sr_outbound}"
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
    }
    # Number of entries in nsg_ids. Can't be calculated. See note above.
    nsg_ids_len = 2
}
############################################################################################
# Create each of the subnets

module "create_subnets" {
    source = "./modules/network/subnets"

    subnet_cidr_map = "${local.subnetPrefixes}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    vnet_name = "${module.create_vnet.vnet_name}"
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
  compute_hostname_prefix   = "retail"
}



###################################################
# Create bastion host

module "create_bastion" {
  source  = "./modules/bastion"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix_bastion = "${var.compute_hostname_prefix_bastion}"
  bastion_instance_count    = "${var.bastion_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  bastion_boot_volume_size_in_gb    = "${var.bastion_boot_volume_size_in_gb}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  bastion_ssh_public_key    = "${var.bastion_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["bastion-ftp"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
}

###################################################
# Create S-FTP Server

module "create_ftp" {
  source  = "./modules/bastion"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix_bastion = "${var.compute_hostname_prefix_ftp}"
  bastion_instance_count    = "${var.ftp_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  bastion_boot_volume_size_in_gb    = "${var.bastion_boot_volume_size_in_gb}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  bastion_ssh_public_key    = "${var.ftp_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["bastion-ftp"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
}



###################################################
# Create Merch server
module "create_app" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix_app = "${var.compute_hostname_prefix_app}"
  compute_instance_count    = "${var.compute_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  compute_boot_volume_size_in_gb    = "${var.compute_boot_volume_size_in_gb}"
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.compute_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["application"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  backendpool_id            = "${module.lb_App.backendpool_id}"

 
}
###################################################
# Create IDM server
module "create_idm" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix_app = "${var.compute_hostname_prefix_idm}"
  compute_instance_count    = "${var.compute_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  compute_boot_volume_size_in_gb    = "${var.compute_boot_volume_size_in_gb}"
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.compute_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["application"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  backendpool_id            = "${module.lb_idm.backendpool_id}"

 
}

###################################################
# Create Integration server
module "create_integ" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix_app = "${var.compute_hostname_prefix_integ}"
  compute_instance_count    = "${var.compute_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  compute_boot_volume_size_in_gb    = "${var.compute_boot_volume_size_in_gb}"
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.compute_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["application"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  backendpool_id            = "${module.lb_Integ.backendpool_id}"

 
}


###################################################
# Create RIA server
module "create_RIA" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix_app = "${var.compute_hostname_prefix_RIA}"
  compute_instance_count    = "${var.compute_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  compute_boot_volume_size_in_gb    = "${var.compute_boot_volume_size_in_gb}"
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.compute_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["application"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  backendpool_id            = "${module.lb_RIA.backendpool_id}"

 
}

###################################################
# Create Internal Load Balancers
module "lb_App" {
  source = "./modules/load_balancer_internal"

  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  tags                = "${var.tags}"  
  prefix              = "${var.compute_hostname_prefix_app}"
  lb_sku              = "${var.lb_sku}"
  frontend_subnet_id  = "${module.create_subnets.subnet_ids["application"]}"
  lb_port             = {
        http = ["80", "Tcp", "80"]
        https = ["443", "Tcp", "443"]
  }
}

module "lb_Integ" {
  source = "./modules/load_balancer_internal"

  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  tags                = "${var.tags}"  
  prefix              = "${var.compute_hostname_prefix_integ}"
  lb_sku              = "${var.lb_sku}"
  frontend_subnet_id  = "${module.create_subnets.subnet_ids["application"]}"
  lb_port             = {
        http = ["80", "Tcp", "80"]
        https = ["443", "Tcp", "443"]
  }
}

module "lb_idm" {
  source = "./modules/load_balancer_internal"

  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  tags                = "${var.tags}"  
  prefix              = "${var.compute_hostname_prefix_idm}"
  lb_sku              = "${var.lb_sku}"
  frontend_subnet_id  = "${module.create_subnets.subnet_ids["application"]}"
  lb_port             = {
        http = ["80", "Tcp", "80"]
        https = ["443", "Tcp", "443"]
        ldap = ["389", "tcp", "389"]
        custom = ["5575", "tcp", "5575"]
  }
}

module "lb_RIA" {
  source = "./modules/load_balancer_internal"

  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  tags                = "${var.tags}"  
  prefix              = "${var.compute_hostname_prefix_RIA}"
  lb_sku              = "${var.lb_sku}"
  frontend_subnet_id  = "${module.create_subnets.subnet_ids["application"]}"
  lb_port             = {
        http = ["80", "Tcp", "80"]
        https = ["443", "Tcp", "443"]
  }
}

############################################################
# Create Application Gateway
