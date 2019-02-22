#######################################################
##  Full Network Security Group, with Security Rules
#######################################################
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.nsg_name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

####################################
##  NSG Rule 
##    SE -- simplified handling of multiple ranges/prefixes, so defintion
##          will force single values to be lists.
####################################

locals {
    baseInbound = {
        name = ""
        priority = "101"
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_ranges =  "*" 
        destination_port_ranges = ""
        source_address_prefix = "VirtualNetwork"   # Note not list.
        destination_address_prefix = "*"
        resource_group_name = "${var.resource_group_name}"
        network_security_group_name = "${var.nsg_name}"
 #       depends_on = [ "azurerm_network_security_group.nsg.${var.nsg_name}" ]
    }
    baseOutbound = {
        name = ""
        priority = "101"
        direction = "Outbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_ranges =  "*"  # unintuitively, this has to be a string rather than a list.
        destination_port_ranges = "*"
        source_address_prefix = "*"        
        destination_address_prefix = "*"
        resource_group_name = "${var.resource_group_name}"
        network_security_group_name = "${var.nsg_name}"    
  #      depends_on = [ "azurerm_network_security_group.nsg.${var.nsg_name}" ]            
    }
}

#TODO: This can be cleaner when TF 0.12 comes out with for/each syntax (i.e., can be done inline, for now call down)
module "inbound_rules" {
    source = "./securityrules"
  #  depends_on = ["module.create_bastion_subnet"]
    rule_overrides = "${var.inboundOverrides}"
    base_rule_value = "${local.baseInbound}"
    basename_prefix = "${var.subnet_id}"
}

module "outbound_rules" {
    source = "./securityrules"
  #  depends_on = ["module.create_bastion_subnet"]
    rule_overrides = "${var.outboundOverrides}"
    base_rule_value = "${local.baseOutbound}"
    basename_prefix = "${var.subnet_id}"
}

