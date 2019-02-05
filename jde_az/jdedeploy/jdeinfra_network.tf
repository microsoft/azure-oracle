# Create a resource group
resource "azurerm_resource_group" "jde-rg" {
  name     = "jde-azure"
  location = "East US"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "jde-vnet" {
  name                = "jde-network"
  resource_group_name = "${azurerm_resource_group.jde-rg.name}"
  location            = "${azurerm_resource_group.jde-rg.location}"
  address_space       = "${var.vpn-cidr}"
}

resource "azurerm_subnet" "PubSubnet" {

}

resource "azurerm_subnet" "PvtSubnet" {

}

resource "azurerm_subnet" "BastSubnet" {

}

resource "azurerm_subnet" "DbSubnet" {
    
}