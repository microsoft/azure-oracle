# To do, before public preview,
#     change the service provider name
#     change the 
# Create the ExpressRoute circuit to OCI under a resource group
resource "azurerm_express_route_circuit" "Az2OCI" {
  name                  = "${var.resource_group_name}-Az2OCI-ER"
  resource_group_name   = "${var.resource_group_name}"
  location              = "${var.location}"
  service_provider_name = "Test Provider With Charges"
  peering_location      = "${var.peering-location}"
  bandwidth_in_mbps     = "${var.bandwidth-in-mbps}"

  sku {
    tier   = "Standard"
    family = "MeteredData"
  }

  tags {
    environment = "Production"
  }
}
