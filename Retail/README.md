# Terraform modules for Retail on Azure
These Terraform modules allow you to create and provision infrastructure for Retail on Azure using Terraform. The modules provide all of the components except for the database itself, which available on OCI via Express Route. 

# Azure Architecture 
The modules will deploy a single Azure VNET with four subnets. Each subnet will have a related NSG to limit traffic within the VNET between application components. An internal load balancer is used to distribute traffic between virtual machines, which are distributed between availibility sets within the desired Azure region.  And application gateway is used for access from the Internet and uses URL path-based routing to direct traffic to the internal load balancer.  A single storage account is used to collect diagnostic logging for each of the VMs.

# Prerequisites

1. Download and install Terraform
2. Download and install Azure CLI
3. An Azure subscription

# Modules
The modules consist of:

1. Compute
2. Bastion 
3. Storage
4. Network (VNET, Subnets and NSGs)
5. Internal Load Balancer 
6. Application Gateway

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

# Information about Modules

## Compute 
This template module is used by "create_app", "create_idm", "create_integ" and "create_RIA". The instance count of each is set to 2.  These VMs will all be deployed as part an Azure availabilty set, one AV-set per application type. Each VM will also be associated with a backend pool on the internal load balancer.

## Bastion
This template module is used by both "create_bastion" and "create_ftp" and the instance count of each is set to 1. Variables for separate SSH keys for access are provided in the template. These VMs will all be deployed with individual public IP addresses and without begin part of an Azure availabilty set.

## Storage
The Storage module creates one randomly named locally redundant storage account. This storage account is used for the Azure diagnostics logs for all the VMs. 

## Network
The network is configured based on a user provide variable of a /16 VNET CIDR, the default being 10.2.0.0/16. Using that CIDR as a starting point, the template will create the four required subnets as /24 networks. Network Security Groups (NSGs) are created on the Application and Bastion-FTP subnets. 

The required subnets are:

1. Application Subnet - Used for the various retail application VMs. Includes and NSG for SSH access from the Bastion-FTP subnet to VMs on this subnet. This subnet does not accept any connections directly from hosts on the Internet.
2. Bastion-FTP Subnet - Used for the Bastion and FTP VMs. Includes an NSG for SSH access to all the VMs on this subnet from the Internet.
3. AppGWSubnet -  Used for the application gateway service.
4. GatewaySubnet - Used for connectivity to the OCI network using ExpressRoute. The name of this subnet can not be changed.

## Internal LB
One internal load balancer is created with four different frontend IP address configurations. The IP addresses used will be dynamically pulled from the Application subnet. Four corresponding backend pools are created and the ports open on each of these pool is configurable in the main.tf.  By default, the "Standard" SKU level is used. The frontend IP addresses are captured as output to be used by the Application Gateway. 

## Application Gateway
One application gateway is created with a single public, frontend IP address.  This frontend configuration includes an HTTP listener and a single Routing Rule. Four backend address pools are created with the IP addresses from the frontend of the internal load balancer used as pool members. Backend HTTP Settings and a URL Path Map is created to route traffic to the various pools using path based routing. 


