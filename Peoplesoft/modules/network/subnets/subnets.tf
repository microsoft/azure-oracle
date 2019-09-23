################################################################
## Create Multiple Subnets based on the lists 
## subnet_names, subnet_cidrs
################################################################
resource "azurerm_subnet" "subnet" {
  name                 = "${element(keys(var.subnet_cidr_map),count.index)}"
  resource_group_name  = "${var.resource_group_name}"  
  virtual_network_name = "${var.vnet_name}"
  address_prefix       = "${element(values(var.subnet_cidr_map),count.index)}"
  count = "${length(var.subnet_cidr_map)}"
  network_security_group_id = "${element(values(var.nsg_ids),count.index)}"
}

locals {
    # a temp map to avoid a dependency between the order in which subnets show up in
    # azurerm_subnet.subnet.*.id and the keys in subnet_cidr_map/nsg_ids.
    subnetNameToID = "${zipmap(keys(var.subnet_cidr_map),azurerm_subnet.subnet.*.id)}"

    subnet_bits = 8   # want 256 entries per subnet.
    # determine difference between VNET CIDR bits and that size subnetBits.
    vnet_cidr_increase = "${32 - element(split("/",var.vnet_cidr),1) - local.subnet_bits}"

}


#TODO: TF 1.12 -- will allow indexed depends_on, so will be able to do the correct thing of having associate depend on iteration of subnet

###################################################
##  Associate the NSG with the Subnet from above.
###################################################
resource "azurerm_subnet_network_security_group_association" "associateSubnetWithNSG" {
  subnet_id                 = "${lookup(local.subnetNameToID, element(keys(var.nsg_ids),count.index))}"
  #subnet_id                 = "${element(azurerm_subnet.subnet.*.id,count.index)}"
  network_security_group_id = "${element(values(var.nsg_ids),count.index)}"
  count = "${var.nsg_ids_len}"
  depends_on = [ "azurerm_subnet.subnet" ]
}

###############################################
# Create stand-alone subnet for AppGW
#############################################
resource "azurerm_subnet" "appgw_subnet" {
  name                 = "appgw"
  resource_group_name  = "${var.resource_group_name}"  
  virtual_network_name = "${var.vnet_name}"
  address_prefix       = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 9)}"

}
