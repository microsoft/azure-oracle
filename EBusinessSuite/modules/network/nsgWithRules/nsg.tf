#######################################################
##  Full Network Security Group, with Security Rules
#######################################################
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.vnet_name}-${var.tier_name}-nsg"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  tags                = "${var.tags}"
  count               = "${local.createSubnetAndNSG}"
  depends_on = ["azurerm_subnet.subnet"]
}

#######################################################
##  Subnet Creation
#######################################################
resource "azurerm_subnet" "subnet" {
  name                 = "${var.vnet_name}-${var.tier_name}-subnet"
  resource_group_name  = "${var.vnet_rg_name}"  
  virtual_network_name = "${var.vnet_name}"
  address_prefix       = "${var.address_prefix}"
  count                = "${local.createSubnetAndNSG}"
#  network_security_group_id = "${element(azurerm_network_security_group.nsg.*.id, 0)}"
}

###################################################
##  Associate the NSG with the Subnet from above.
##
##  Note that the set of subnets created above is controlled by var.subnet_cidr_map, which may
##  have more entries than var.nsg_ids, which maps subnet names to NSG ids.  That is, there
##  may be subnets created which purposely do not get an associated NSG.
###################################################
resource "azurerm_subnet_network_security_group_association" "associateSubnetWithNSG" {
  subnet_id                 = "${element(azurerm_subnet.subnet.*.id, 0)}"
  network_security_group_id = "${element(azurerm_network_security_group.nsg.*.id, 0)}"
  count = "${local.createSubnetAndNSG}"
  depends_on = [ "azurerm_subnet.subnet" ]
}

####################################
##  NSG Rule 
##    SE -- simplified handling of multiple ranges/prefixes, so defintion
##          will force single values to be lists.
####################################

locals {
    createSubnetAndNSG = "${var.createSubnetAndNSG ? 1 : 0}"
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
        network_security_group_name = "${element(concat(azurerm_network_security_group.nsg.*.name, list("0")), 0)}" 
    }
    baseOutbound = {
        name = ""
        priority = "101"
        direction = "Outbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_ranges =  "*"
        destination_port_ranges = "*"
        source_address_prefix = "*"        
        destination_address_prefix = "*"
        resource_group_name = "${var.resource_group_name}"
        network_security_group_name = "${element(concat(azurerm_network_security_group.nsg.*.name, list("0")), 0)}"             
    }
}

#TODO: This can be cleaner when TF 0.12 comes out with for/each syntax (i.e., can be done inline, for now call down)
module "inbound_rules" {
    source = "./securityrules"
    rule_overrides = "${var.inboundOverrides}"
    base_rule_value = "${local.baseInbound}"
    basename_prefix = "${element(concat(azurerm_network_security_group.nsg.*.name, list("0")), 0)}"
    createRules = "${local.createSubnetAndNSG}"
}

module "outbound_rules" {
    source = "./securityrules"
    rule_overrides = "${var.outboundOverrides}"
    base_rule_value = "${local.baseOutbound}"
    basename_prefix = "${element(concat(azurerm_network_security_group.nsg.*.name, list("0")), 0)}"
    createRules = "${local.createSubnetAndNSG}"
}
