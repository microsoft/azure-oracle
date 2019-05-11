# Terraform modules for PeopleSoft on Azure
These Terraform modules allow you to create and provision infrastructure for PeopleSoft on Azure using Terraform. The modules provide all of the components for PeopleSoft except for the database itself, which available on OCI via Express Route. 

# Prerequisites

1. Download and install Terraform
2. Download and install Azure CLI
3. An Azure subscription

# Modules
The modules consist of:

1. Compute
2. Bastion
3. Elastic
4. Load Balancer
5. Network


# Azure Architecture 
The modules will deploy a single Azure VNET with X subnets. Each subnet will have a related NSG to control traffic between different application layers.  

