# Terraform modules for Retail on Azure
These Terraform modules allow you to create and provision infrastructure for Retail on Azure using Terraform. The modules provide all of the components except for the database itself, which available on OCI via Express Route. 

# Prerequisites

1. Download and install Terraform
2. Download and install Azure CLI
3. An Azure subscription

# Modules
The modules consist of:

1. Compute
2. Bastion
3. Storage
4. Network
5. Internal Load Balancer
6. Application Gateway

# Azure Architecture 
The modules will deploy a single Azure VNET with X subnets. Each subnet will have a related NSG to limit traffic within the VNET between application components. An internal load balancer is used to distribute traffic between virtual machines, which are distributed between availibility sets within the desired Azure region.  And application gateway is used for access from the Internet and uses URL path-based routing to direct traffic to the internal load balancer.  A single storage account is used to collect diagnostic logging for each of the VMs.

# Inputs required in the terraform.tfvars file
The modules expect the following variables to be set via tfvars:

| Arguement      | Description   | 
| :------------: | :----------: | 
| location | Azure Region  | 
| tags | Any desired tags |
| admin_password | Can be left blank with empty quotes |
| custom_data | Can be left blank with empty quotes |
| tenant_id | Azure Tenant GUID |
| subscription-id | Azure Subscription GUID |

