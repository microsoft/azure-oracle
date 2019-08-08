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
}

#TODO: TF 1.12 -- will allow indexed depends_on, so will be able to do the correct thing of having associate depend on iteration of subnet

locals {
    # a temp map to avoid a dependency between the order in which subnets show up in
    # azurerm_subnet.subnet.*.id and the keys in subnet_cidr_map/nsg_ids.
    subnetNameToID = "${zipmap(keys(var.subnet_cidr_map),azurerm_subnet.subnet.*.id)}"
}
###################################################
##  Associate the NSG with the Subnet from above.
##
##  Note that the set of subnets created above is controlled by var.subnet_cidr_map, which may
##  have more entries than var.nsg_ids, which maps subnet names to NSG ids.  That is, there
##  may be subnets created which purposely do not get an associated NSG.
###################################################
resource "azurerm_subnet_network_security_group_association" "associateSubnetWithNSG" {
  subnet_id                 = "${lookup(local.subnetNameToID, element(keys(var.nsg_ids),count.index))}"
  network_security_group_id = "${element(values(var.nsg_ids),count.index)}"
  count = "${var.nsg_ids_len}"
  depends_on = [ "azurerm_subnet.subnet" ]
}