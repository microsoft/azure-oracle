
#########################################################

# Create application security groups

resource "azurerm_application_security_group" "prosched" {
  name                = "asg-prosched"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}" 
  tags                = "${var.tags}"
}

resource "azurerm_application_security_group" "compute" {
  name                = "asg-compute"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}" 
  tags                = "${var.tags}"
}