
locals {
    ## Key = subnet name, Value = CIDR prefixes e.g., 2.2.2.0/28)
    subnetBits = 8   # want 256 entries per subnet.
    # determine difference between VNET CIDR bits and that size subnetBits.
    vnetCidrIncrease = "${32 - element(split("/",var.vnet_cidr),1) - local.subnetBits}"
    subnetPrefixes = {
        application     = "${cidrsubnet(var.vnet_cidr, local.vnetCidrIncrease, 1)}"
        database        = "${cidrsubnet(var.vnet_cidr, local.vnetCidrIncrease, 2)}"
        bastion         = "${cidrsubnet(var.vnet_cidr, local.vnetCidrIncrease, 3)}"
     #   presentation    = "${cidrsubnet(var.vnet_cidr, local.vnetCidrIncrease, 4)}"
     #   gateway         = "${cidrsubnet(var.vnet_cidr, local.vnetCidrIncrease, 5)}"
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
            source_address_prefix = "VIRTUALNETWORK"
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
            name = "App->DB"
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
  location = "${var.deployment_location}"
}

############################################################################################
# Create the VNET
module "create_vnet" {
    source = "./modules/network/vnet"

    vnet_name = "${var.vnet_name}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location = "${var.deployment_location}"
    vnet_cidr = "${var.vnet_cidr}"
}

############################################################################################
# Create each of the subnets
module "create_subnets" {
    source = "./modules/network/subnets"

    subnet_cidr_map = "${local.subnetPrefixes}"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    vnet_name = "${module.create_vnet.vnet_name}"
}

############################################################################################
# Create each of the Network Security Groups

###############################################################
# Bastion NSG
/*
module "create_networkSGsForBastion" {
    source = "./modules/network/nsgWithRules"

    nsg_name = "bastion_nsg"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    location = "${var.deployment_location}"
    subnet_id = "${module.create_subnets.subnet_names["bastion"]}"
    inboundOverrides  = "${local.bastion_sr_inbound}"
    outboundOverrides = "${local.bastion_sr_outbound}"
}
*/

