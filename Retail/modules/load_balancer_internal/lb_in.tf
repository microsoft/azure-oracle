# Azure load balancer module

resource "azurerm_lb" "inlb" {
  name                = "${var.prefix}-lb"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"
  tags                = "${var.tags}"
  sku                 = "${var.lb_sku}"

  frontend_ip_configuration {
    name                          = "${var.frontend_name}"
    private_ip_address_allocation = "dynamic"
    subnet_id                 = "${var.frontend_subnet_id}"

  }
}

resource "azurerm_lb_backend_address_pool" "inlb" {
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.inlb.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "inlb" {
  count               = "${length(var.lb_port)}"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.inlb.id}"
  name                = "${element(keys(var.lb_port), count.index)}"
  protocol            = "${element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 1)}"
  port                = "${element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 2)}"
  interval_in_seconds = "${var.lb_probe_interval}"
  number_of_probes    = "${var.lb_probe_unhealthy_threshold}"
}

resource "azurerm_lb_rule" "inlb" {
  count                          = "${length(var.lb_port)}"
  resource_group_name            = "${var.resource_group_name}"
  loadbalancer_id                = "${azurerm_lb.inlb.id}"
  name                           = "${element(keys(var.lb_port), count.index)}"
  protocol                       = "${element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 1)}"
  frontend_port                  = "${element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 0)}"
  backend_port                   = "${element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 2)}"
  frontend_ip_configuration_name = "${var.frontend_name}"
  enable_floating_ip             = false
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.inlb.id}"
  idle_timeout_in_minutes        = 5
  probe_id                       = "${element(azurerm_lb_probe.inlb.*.id,count.index)}"
  depends_on                     = ["azurerm_lb_probe.inlb"]
}