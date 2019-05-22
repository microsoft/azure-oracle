resource "azurerm_network_security_group" "jde-nsg" {
  name                = "${var.nsg_name}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

resource "azurerm_subnet_network_security_group_association" "test" {
  subnet_id                 = "${var.subnet_id}"
  network_security_group_id = "${azurerm_network_security_group.jde-nsg.id}"
  depends_on = ["azurerm_network_security_group.jde-nsg"]
}