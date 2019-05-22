output "vnet_gw_id" {
    value = "${element(azurerm_virtual_network_gateway.vnet-gw.*.id, 0)}"
}

output "er_gw_name" {
    value = "${local.name}"
}