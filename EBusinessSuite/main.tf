# ebs/main.tf

locals {
    subnet_bits = 8   # want 256 entries per subnet.
    # determine difference between VNET CIDR bits and that size subnetBits.
    vnet_cidr_increase = "${32 - element(split("/",var.vnet_cidr),1) - local.subnet_bits}"
    subnetPrefixes = {
        application     = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 1)}"
        database        = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 2)}"
        bastion         = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 3)}"
     #   presentation    = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 4)}"
     #   gateway         = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 5)}"
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
            source_address_prefix = "AzureLoadBalancer"  # input from the Load Balancer only.             
            destination_port_ranges = "8000" 
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
            destination_address_prefix = "${local.subnetPrefixes["database"]}"  # out to DB
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
}

############################################################################################
# Create the VNET
module "create_vnet" {
    source = "./modules/network/vnet"

    resource_group_name = "${azurerm_resource_group.rg.name}"
    location            = "${var.location}"
    vnet_cidr           = "${var.vnet_cidr}"
    vnet_name           = "${var.vnet_name}"
}

/*
# Create bastion host subnet
module "bastion_subnet" {
  source  = "./modules/network/subnets"
  
  resource_group_name = "${azurerm_resource_group.rg.name}"
  vnet_name            = "${module.create_vnet.vnet_name}"
  subnet_cidr_map      =  {bastion = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 1)}"}
}
# Create Application subnet
module "app_subnet" {
  source  = "./modules/network/subnets"
  
  resource_group_name = "${azurerm_resource_group.rg.name}"
  vnet_name            = "${module.create_vnet.vnet_name}"
  subnet_cidr_map      =  {application = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 2)}"}
}
*/

###############################################################
# Create each of the Network Security Groups
###############################################################

module "create_networkSGsForBastion" {
    source = "./modules/network/nsgWithRules"

    nsg_name = "bastion_nsg"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location = "${var.location}"
    subnet_id = "${module.create_subnets.subnet_names["bastion"]}"
    inboundOverrides  = "${local.bastion_sr_inbound}"
    outboundOverrides = "${local.bastion_sr_outbound}"
}

module "create_networkSGsForApplication" {
    source = "./modules/network/nsgWithRules"

    nsg_name = "application_nsg"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location = "${var.location}"
    subnet_id = "${module.create_subnets.subnet_names["application"]}"
    inboundOverrides  = "${local.application_sr_inbound}"
    outboundOverrides = "${local.application_sr_outbound}"
}

module "create_networkSGsForDatabase" {
    source = "./modules/network/nsgWithRules"

    nsg_name = "database_nsg"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location = "${var.location}"
    subnet_id = "${module.create_subnets.subnet_names["database"]}"
    inboundOverrides  = "${local.database_sr_inbound}"
    outboundOverrides = "${local.database_sr_outbound}"
}

############################################################################################
# Create each of the subnets
module "create_subnets" {
    source = "./modules/network/subnets"

    subnet_cidr_map = "${local.subnetPrefixes}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    vnet_name = "${module.create_vnet.vnet_name}"
    nsg_ids = "${zipmap(
        list("bastion", "database", "application"),
        list(module.create_networkSGsForBastion.nsg_id,
             module.create_networkSGsForDatabase.nsg_id,
             module.create_networkSGsForApplication.nsg_id))}"
}
/* 
# Create bastion host
module "create_bastion" {
  source  = "./modules/bastion"

  compartment_ocid        = "${var.compartment_ocid}"
  AD                      = "${var.AD}"
  availability_domain     = ["${data.template_file.deployment_ad.*.rendered}"]
  bastion_hostname_prefix = "${var.ebs_env_prefix}bas${substr(var.region, 3, 3)}"
  bastion_image           = "${data.oci_core_images.InstanceImageOCID.images.0.id}"
  bastion_instance_shape  = "${var.bastion_instance_shape}"
  bastion_subnet          = ["${module.bastion_subnet.subnetid}"]
  bastion_ssh_public_key  = "${var.bastion_ssh_public_key}"
  }
 */
# Create Application server
/*
module "create_app" {
  source  = "./modules/compute"

  vm_hostname               = "${var.vm_hostname}"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix   = "${var.compute_hostname_prefix}"
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
  nb_instances              = "${var.nb_instances}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${element(module.app_subnet.subnet_ids, 0)}"
  backendpool_id            = "${module.ebslb.backendpool_id}"
  #TODO network_security_group_id = "${module.app_nsg.nsg_id}"
}

# Create Load Balancer
module "ebslb" {
  source              = "./modules/load balancer"
  resource_group_name    = "${azurerm_resource_group.ebs-rg.name}"
  location            = "${var.location}"
  prefix              = "ebs"
  lb_sku              = "${var.lb_sku}"
  frontend_subnet_id  = "${element(values(module.app_subnet.subnet_ids), 0)}"
  tags                = "${var.tags}"

  "lb_port" {
    http = ["8080", "Tcp", "8888"]
  }
}
