# Peoplesoft/main.tf

locals {
    subnet_bits = 8   # want 256 entries per subnet.
    # determine difference between VNET CIDR bits and that size subnetBits.
    vnet_cidr_increase = "${32 - element(split("/",var.vnet_cidr),1) - local.subnet_bits}"
    subnetPrefixes = {
        application     = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 1)}"
        webserver       = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 2)}"
        elasticsearch   = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 3)}"
        client          = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 4)}"
        bastion         = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 5)}"
    }

    #####################
    ## NSGs
    #Note that only one of prefix or prefixes is allowed and keywords can't be in the list.

    bastion_sr_inbound = [
        {   # SSH from outside
            source_port_ranges = "*" 
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
            source_address_prefix = "${local.subnetPrefixes["bastion"]}"              
            destination_port_ranges = "22" 
            destination_address_prefix = "*"             
        },
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["webserver"]}"              
            destination_port_ranges = "9033-9039"
            destination_address_prefix = "*"           
        },
        
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["elasticsearch"]}"              
            destination_port_ranges = "2320-2321"
            destination_address_prefix = "*"              
        }
    ]

    application_sr_outbound = [
        {  # SSH to any of the servers
            source_port_ranges =  "*" 
            source_address_prefix = "VirtualNetwork"
            destination_port_ranges =  "22" 
        
        }
    ]
    webserver_sr_inbound = [
        {
            source_port_ranges =  "*" 
            source_address_prefix = "AzureLoadBalancer"  # input from the Load Balancer only.             
            destination_port_ranges = "8000" 
            destination_address_prefix = "*"             
        },
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["bastion"]}"                
            destination_port_ranges = "22" 
            destination_address_prefix = "*"             
        },
               {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["elasticsearch"]}"                
            destination_port_ranges = "*" 
            destination_address_prefix = "*"             
        }
    ]

    webserver_sr_outbound = [
                {
            source_port_ranges =  "*" 
            source_address_prefix = "*"  # ob to Application Servers               
            destination_port_ranges = "*" 
            destination_address_prefix = "${local.subnetPrefixes["application"]}"             
        },
                   {
            source_port_ranges =  "*" 
            source_address_prefix = "*"              
            destination_port_ranges = "9200" 
            destination_address_prefix = "${local.subnetPrefixes["elasticsearch"]}"    # ob to Elastic Servers            
        }
    ]
    elasticsearch_sr_inbound = [
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["webserver"]}"             
            destination_port_ranges = "9200"
            destination_address_prefix = "*"             
        },
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["bastion"]}"                
            destination_port_ranges = "22" 
            destination_address_prefix = "*"             
        }
    ]

    elasticsearch_sr_outbound = [
                {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["application"]}"  # ob to Application Servers               
            destination_port_ranges = "9033-9039" 
            destination_address_prefix = "*"             # Need to support ASG
        },
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["webserver"]}"  # ob to WebServers            
            destination_port_ranges = "8000" 
            destination_address_prefix = "*"            
        }
    ]

        toolsclient_sr_inbound = [
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["application"]}"             
            destination_port_ranges = "5985-5986"
            destination_address_prefix = "*"             
        },
        {
            source_port_ranges =  "*" 
            source_address_prefix = "${local.subnetPrefixes["bastion"]}"                
            destination_port_ranges = "22" 
            destination_address_prefix = "*"             
        }
    ]

    toolsclient_sr_outbound = [

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

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.vnet_name}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  address_space       = ["${var.vnet_cidr}"]  
  tags                = "${var.tags}"
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
 zone_name = "${azurerm_dns_zone.oci_vcn_dns.id}"
 ttl = 3600
 records = ["${var.db_scan_ip_addresses}"]
}

###############################################################
# Create each of the Network Security Groups
###############################################################

module "create_networkSGsForBastion" {
    source = "./modules/network/nsgWithRules"

    nsg_name            = "${azurerm_virtual_network.vnet.name}-nsg-bastion"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.location}"
    tags                = "${var.tags}"    
    subnet_id           = "${module.create_subnets.subnet_names["bastion"]}"
    inboundOverrides    = "${local.bastion_sr_inbound}"
    outboundOverrides   = "${local.bastion_sr_outbound}"
}

module "create_networkSGsForApplication" {
    source = "./modules/network/nsgWithRules"

    nsg_name = "${azurerm_virtual_network.vnet.name}-nsg-application"    
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location = "${var.location}"
    tags = "${var.tags}"    
    subnet_id = "${module.create_subnets.subnet_names["application"]}"
    inboundOverrides  = "${local.application_sr_inbound}"
    outboundOverrides = "${local.application_sr_outbound}"
}
module "create_networkSGsForWebserver" {
    source = "./modules/network/nsgWithRules"

    nsg_name            = "${azurerm_virtual_network.vnet.name}-nsg-webserver"    
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.location}"
    tags                = "${var.tags}"
    subnet_id           = "${module.create_subnets.subnet_names["webserver"]}"
    inboundOverrides    = "${local.database_sr_inbound}"
    outboundOverrides   = "${local.database_sr_outbound}"
}

module "create_networkSGsForElasticsearch" {
    source = "./modules/network/nsgWithRules"

    nsg_name            = "${azurerm_virtual_network.vnet.name}-nsg-elasticsearch"    
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.location}"
    tags                = "${var.tags}"
    subnet_id           = "${module.create_subnets.subnet_names["elasticsearch"]}"
    inboundOverrides    = "${local.database_sr_inbound}"
    outboundOverrides   = "${local.database_sr_outbound}"
}

module "create_networkSGsForClient" {
    source = "./modules/network/nsgWithRules"

    nsg_name            = "${azurerm_virtual_network.vnet.name}-nsg-client"    
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.location}"
    tags                = "${var.tags}"
    subnet_id           = "${module.create_subnets.subnet_names["client"]}"
    inboundOverrides    = "${local.database_sr_inbound}"
    outboundOverrides   = "${local.database_sr_outbound}"
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
        bastion = "${module.create_networkSGsForBastion.nsg_id}"
        application = "${module.create_networkSGsForApplication.nsg_id}"
        webserver = "${module.create_networkSGsForWebserver.nsg_id}"
        elasticsearch = "${module.create_networkSGsForElasticsearch.nsg_id}"
        client = "${module.create_networkSGsForClient.nsg_id}"
    }
    nsg_ids_len = 5
    # Number of entries in nsg_ids. Can't be calculated. See note above.
    
}

############################################################################################
# Create each of the subnets
module "create_subnets" {
    source = "./modules/network/subnets"

    subnet_cidr_map = "${local.subnetPrefixes}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    vnet_name = "${azurerm_virtual_network.vnet.name}"
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
  compute_hostname_prefix   = "${var.compute_hostname_prefix}"
}



###################################################
# Create bastion host

module "create_bastion" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix   = "${var.compute_hostname_prefix_bastion}"
  compute_instance_count    = "${var.bastion_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  compute_boot_volume_size_in_gb    = "${var.bastion_boot_volume_size_in_gb}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.bastion_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["bastion"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  create_av_set             = false  
  create_public_ip          = true
  create_data_disk          = false
  assign_bepool             = false
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
  
}


###################################################
# Create Application server
module "create_app" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix   = "${var.compute_hostname_prefix_app}"
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
  create_av_set             = true 
  create_public_ip          = false
  create_data_disk          = false
  assign_bepool             = false
 
}


###################################################
# Create Webserver
module "create_web" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix   = "${var.compute_hostname_prefix_web}"
  compute_instance_count  = "${var.webserver_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  compute_boot_volume_size_in_gb    = "${var.webserver_boot_volume_size_in_gb}"
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.webserver_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["webserver"]}"
  backendpool_id            = "${module.lb.backendpool_id}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  create_av_set             = true 
  create_public_ip          = false
  create_data_disk          = false
  assign_bepool             = true
}

###################################################
# Create Elastic Search server
module "create_es" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix   = "${var.compute_hostname_prefix_es}"
  compute_instance_count    = "${var.elastic_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  compute_boot_volume_size_in_gb    = "${var.elastic_boot_volume_size_in_gb}"
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.elastic_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["elasticsearch"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  create_av_set             = true 
  create_public_ip          = false
  create_data_disk          = false
  assign_bepool             = false
}

###################################################
# Create Process Scheduler server
module "create_ps" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix   = "${var.compute_hostname_prefix_ps}"
  compute_instance_count   = "${var.prosched_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  compute_boot_volume_size_in_gb    = "${var.prosched_boot_volume_size_in_gb}"
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.prosched_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["application"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  create_av_set             = true 
  create_public_ip          = false
  create_data_disk          = false
  assign_bepool             = false

 
}
###################################################
# Create Tools Client machine

module "create_toolsclient" {
  source  = "./modules/compute"

  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix  = "${var.compute_hostname_prefix_tc}"
  compute_instance_count    = "${var.toolsclient_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  compute_boot_volume_size_in_gb    = "${var.toolsclient_boot_volume_size_in_gb}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.toolsclient_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${module.create_subnets.subnet_ids["client"]}"
  boot_diag_SA_endpoint     = "${module.create_boot_sa.boot_diagnostics_account_endpoint}"
  create_av_set             = false
  create_public_ip          = false
  create_data_disk          = false
  assign_bepool             = false
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
}


###################################################
# Create Load Balancer
module "lb" {
  source = "./modules/load_balancer"

  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  tags                = "${var.tags}"  
  prefix              = "${var.compute_hostname_prefix_web}"
  lb_sku              = "${var.lb_sku}"
  frontend_subnet_id  = "${module.create_subnets.subnet_ids["webserver"]}"
  lb_port             = {
        http = ["8000", "Tcp", "8000"]
  }
}