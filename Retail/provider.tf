#########################
## Azure ARM Provider
#########################
provider "azurerm" {
    version= ">=1.21.0"
    tenant_id       = "${var.tenant_id}"
    subscription_id = "${var.subscription_id}"
    client_id       = "${var.client_id}"
    client_secret   = "${var.client_secret}"   
    partner_id      = "e7a6fb4f-fce6-57a3-abfc-c6dfafd44692"
}

provider "random" {
    version= ">=2.0"
}

