resource "azurerm_resource_group" "er_rg" {
  name = "${var.resource_group_name}"
  location = "${var.deployment_location}"
}

# Create the ExpressRoute circuit to OCI under a resource group
resource "azurerm_express_route_circuit" "Az2OCI" {
  name                  = "${azurerm_resource_group.er_rg.name}-Az2OCI-ER-Circuit"
  resource_group_name   = "${azurerm_resource_group.er_rg.name}"
  location              = "${var.deployment_location}"
  service_provider_name = "Oracle Cloud FastConnect"
  peering_location      = "${var.peering_location}"
  bandwidth_in_mbps     = "${var.bandwidth_in_mbps}"

  sku {
    tier   = "${var.expressroute_sku}"
    family = "${var.expressroute_billing_model}"
  }
}
