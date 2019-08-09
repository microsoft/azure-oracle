#########################
## Azure ARM Provider
#########################
provider "azurerm" {
    version= ">=1.21.0"
    tenant_id       = "${var.tenant_id}"
    subscription_id = "${var.subscription_id}"
    # client_id       = "${var.client_id}"
    # client_secret   = "${var.client_secret}"   
}

provider "random" {
    version= ">=2.0"
}

#provider "null" {
#   version= ">=2.0.0"
#}