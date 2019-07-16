provider "azurerm" {
    version= ">=1.21.0"
    tenant_id       = "${var.tenant_id}"
    subscription_id = "${var.subscription_id}"
    client_id       = "${var.client_id}"
    client_secret   = "${var.client_secret}"
    partner_id      = "aa90d588-67de-5711-b249-5cc064d35376"
}