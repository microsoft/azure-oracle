#########################
## Azure ARM Provider
#########################
provider "azurerm" {
    version= ">=1.28.0"
    tenant_id       = "${var.tenant_id}"
    subscription_id = "${var.subscription_id}"
    client_id       = "${var.client_id}"
    client_secret   = "${var.client_secret}" 
    partner_id      = "1ec53238-c562-5ff9-89f6-558763be3779"  
}

provider "random" {
    version= ">=2.0"
}

#provider "null" {
#   version= ">=2.0.0"
#}