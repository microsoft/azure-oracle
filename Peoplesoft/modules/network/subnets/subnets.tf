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

###################################################
##  Associate the NSG with the Subnet from above.
###################################################
resource "azurerm_subnet_network_security_group_association" "associateSubnetWithNSG" {
  subnet_id                 = "${element(azurerm_subnet.subnet.*.id,count.index)}"
  network_security_group_id = "${element(values(var.nsg_ids),count.index)}"
  count = "${var.nsg_ids_len}"
  depends_on = [ "azurerm_subnet.subnet" ]
}

