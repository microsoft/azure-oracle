# Terraform modules for PeopleSoft on Azure
These Terraform modules allow you to create and provision infrastructure for PeopleSoft on Azure using Terraform. The modules provide all of the components for PeopleSoft except for the database itself, which available on OCI via Express Route and the interconnection between the two cloud networks, which can be configured using the X template.

# Prerequisites

1. Download and install Terraform
2. Download and install Azure CLI
3. An Azure subscription

# Modules
The modules consist of:

1. Compute
1. Load Balancer
1. Network
1. Storage


# Azure Architecture 
The modules will deploy a single Azure VNET with at least 5 subnets. Each subnet will have a related NSG to control traffic between different application layers.  

# Information about Modules

## Compute 
This template module is used to create all VM resources. Some configuration is dependent on the true/false settings for AV Set, Public IP, Backend Pools and Data Disks. Machines deployed with AV sets need to have two VMs of the same type deployed. 

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
1. GatewaySubnet - Used for connectivity to the OCI network using ExpressRoute. The name of this subnet can not be changed and depending on your Azure configuration, may already exist.  

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
admin_password  = "<GUID>"
custom_data     = "<GUID>"
tenant_id       = "<GUID>"
subscription_id = "<GUID>"
```

