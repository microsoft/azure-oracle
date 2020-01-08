#########################
## Azure ARM Provider
#########################

# Terraform version

terraform {
  required_version = ">= 0.11.11"
}

provider "azurerm" {
    version= ">=1.21.0"
    tenant_id       = "${var.tenant_id}"
    subscription_id = "${var.subscription_id}"
    client_id       = "${var.client_id}"
    client_secret   = "${var.client_secret}"
    partner_id      = "3662be22-8a0f-5a88-a9ef-f3ee6c43e241"
}

provider "random" {
    version= ">=2.0"
}

#provider "null" {
#   version= ">=2.0.0"
#}