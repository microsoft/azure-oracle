output "vnet_gw_id" {
    value = "${element(concat(azurerm_virtual_network_gateway.vnet-gw.*.id, list("")), 0)}"
}

output "er_gw_name" {
    value = "${local.name}"
}