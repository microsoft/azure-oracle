# Create Multiple Subnets based on the lists subnet_names, subnet_cidrs
resource "azurerm_subnet" "subnet" {
  name                 = "${element(keys(var.subnet_cidr_map),count.index)}"
  resource_group_name  = "${var.resource_group_name}"
  virtual_network_name = "${var.vnet_name}"
  address_prefix       = "${element(values(var.subnet_cidr_map),count.index)}"
  count = "${length(var.subnet_cidr_map)}"
}