provider "azurerm" {
    version= "=1.21.0"
    tenant_id       = "${var.tenant_id}"
    subscription_id = "${var.subscription_id}"
    client_id       = "${var.client_id}"
    client_secret   = "${var.client_secret}"
    partner_id = "1982f97d-5826-5438-a036-af42cbfa427f"
}