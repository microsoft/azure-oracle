# Terraform modules for PeopleSoft on Azure
These Terraform modules allow you to create and provision infrastructure for PeopleSoft on Azure using Terraform. The modules provide all of the components for PeopleSoft except for the database itself, which available on OCI via Express Route and the interconnection between the two cloud networks, which can be configured using the X template.

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

# Information about Modules

## Compute 
This template module is used by "create_app", "create_prosched", and "create_es". The instance count of each is set to 2.  These VMs will all be deployed as part an Azure availabilty set, one AV-set per application type. Each VM will also be associated with a backend pool on the internal load balancer.

## Bastion
This template module is used by "create_bastion" and the instance count is set to 1. Variables for separate SSH keys for access are provided in the template. This VM will be deployed with individual public IP addresses and without begin part of an Azure availabilty set.

## Webserver
This template module is used by "create_web". It is very similar to the compute module with the addition of the associations to the backend pool of the load balancer. The instance count of each is set to 2.  These VMs will all be deployed as part an Azure availabilty set, one AV-set per application type. Each VM will also be associated with a backend pool on the internal load balancer.

## Tools Client
This template module is used by "create_toolsclient". It is very similar to the bastion module and the instance count is set to 1. Variables for separate SSH keys for access are provided in the template. This VM will be deployed without begin part of an Azure availabilty set.

## Storage
The Storage module creates one randomly named locally redundant storage account. This storage account is used for the Azure diagnostics logs for all the VMs. 

## Network
The network is configured based on a user provide variable of a /16 VNET CIDR, the default being 10.2.0.0/16. Using that CIDR as a starting point, the template will create the four required subnets as /24 networks. Network Security Groups (NSGs) are created on the Application and Bastion-FTP subnets. 

The required subnets are:

1. Application Subnet - Used for application and process scheduler VMs. Includes and NSG for SSH access from the Bastion subnet to VMs on this subnet. This subnet does not accept any connections directly from hosts on the Internet.
1. Bastion Subnet - Used for the Bastion VM. Includes an NSG for SSH access to all the VMs on this subnet from the Internet.
1. Webserver Subnet -
1. Elastic Search Subnet -
1. Client Subnet -
1. GatewaySubnet - Used for connectivity to the OCI network using ExpressRoute. The name of this subnet can not be changed.

## Load Balancer
One load balancer is created with one frontend IP address configuration with an Public IP address. Four corresponding backend pools are created and the ports open on each of these pool is configurable in the main.tf.  By default, the "Standard" SKU level is used. 

# Getting Started

This template assumes that an Azure VNET using the 10.2.0.0/16 address space is fitting for your network. If that is not the case, update the VNET_CIDR Variable to reflect an address space that will not conflict with any other networks in your ecosystem. The number used to determine the subnet prefixes can also be adjusted to prevent overlap if you will be running more that one Oracle application in the same Azure VNET. 

## Inputs required in the terraform.tfvars file
The modules expect the following variables to be set via tfvars:

| Arguement      | Description   | 
| :------------: | :----------: | 
| location | Azure Region  | 
| tags | Any desired tags |
| admin_password | Can be left blank with empty quotes |
| custom_data | Can be left blank with empty quotes |
| tenant_id | Azure Tenant GUID |
| subscription-id | Azure Subscription GUID |

A sample terraform.tfvars file can look like this:

```
location    = "westus2"
tags    = {
    application = "Peoplesoft"
}
admin_password  = ""
custom_data     = ""
tenant_id       = "72f988bf-86f1-41af-91ab-2d7cd011db47"
subscription_id = "2fa766df-ed46-4e63-92cb-3c53e7dde77d"
```

