# Introduction

The terraform scripts contained here allow you to deploy the cross-cloud inter-connect between Microsoft and Oracle Cloud Infrastructure.

# Conceptual Overview

Microsoft and Oracle have partnered together to allow customers to maximize their investments in the two companies by connecting the two clouds together by a high throughput, low latency secure connection. This allows customers to deploy solutions that span these two clouds and take advantage of the best of both worlds.

Microsoft Azure uses ExpressRoute, whereas OCI uses FastConnect to connect at the common edge site without the need for an intermediate service provider. Due to the use of ExpressRoute and FastConnect, customers are able to peer a VNET in Azure with a VCN in OCI as long as the private IP address space does not overlap. Peering the two networks allows one machine in the VNET to communicate to a machine in the OCI VCN as if it were in the same VNET. 

The following is a high-level conceptual diagram of the application architecture as split across Microsoft Azure and Oracle Cloud Infrastructure

![Cross-cloud Architecture - Highlevel overview](./../_images/cross-cloud.png)

# Getting Started

## Pre-Requisites

- [An Azure Subscription](https://azure.microsoft.com/en-us/free/)
- [Oracle Cloud Infrastructure Tenancy](https://cloud.oracle.com/en_US/tryit)
- [White-listed for the Azure-OCI Cross-Cloud Capability](<linkTBD>)
- [Terraform Installed on your machine](https://www.terraform.io/downloads.html)

## Instructions

### Setup the Terraform scripts

1. Open the file [env_vars](./../env_vars) (or [env_vars.ps1](./../env_vars.ps1) if you do not have the Windows Sub-system for Linux (WSL) or GitBash installed). Add the details regarding your Azure account. Save the file and close it.

1. Execute the following command from your shell and naviagate to the root folder and execute following command:
    - (For Linux or WSL/GitBash) `$ source env-vars`
    - (For Older versions of Windows) `> env-vars.ps1`

### Create an Azure Express Route Circuit

1. Open the [express_route_input.json](./input/express_route_input.json) file and fill in the information as required. Details regarding what information is expected can be found [below](#expressroutecircuit). Save and close the file.

1. Navigate to the `InterConnect` folder (if you haven't already) and run a terraform init command:
    
    `$ terraform init`

1. You should see the following output:

    ![ExpressRoute - Terraform Init](./../_images/express_route_terraform_init.png)

1. Next, run the `terraform apply` command as follows:

    `$ terraform apply -var-file ./../input/express_route_input.json`

1. This will create the required Azure resources. You will see the output as follows. Please copy the `expressroute_service_key`. **You will need it to create the OCI FastConnect Circuit**.

    ![](./../_images/express_route_service_key.png)

#### What will this do?
Running through the above instructions will create an ExpressRoute circuit and connect a VNET (new or existing) to the ExpressRoute Circuit. To connect the VNET to the ExpressRoute circuit, a GatewaySubnet (/27 or larger) will be created in the VNET along with a Virtual Network Gateway (Ultra Performance SKU). In addition, ExpressRoute peering of type 'AzurePrivatePeering' will be setup. This will allow you to connect the ExpressRoute Circuit and the VNET to the FastConnect circuit and the VCN.

At the end of provisioning, The ExpressRoute service key will be output, which will be required to setup the Oracle FastConnect circuit.

### Setting up the Oracle FastConnect Circuit

TO-DO> Setup FastConnect, VCN and DRG

# Terraform Variables

## Express Route Circuit

- `resource_group_name`: This is the resource group that you would like to deploy your ExpressRoute circuit in. If you specify a resource group that does not exist, it will be created for you.
- `location`: The location where the resource group should be created. For a list of all Azure locations, please consult [this link](http://azure.microsoft.com/en-us/regions/) or run `az account list-locations --output table`.
    > **Note**: Please add the region name as shown in the link above. For example, US East region code 'East US'.
- `peering-location`: The name of the peering location and not the Azure resource location.
- `bandwidth-in-mbps`: The bandwidth in Mbps of the ExpressRoute circuit being created. Round down the Mb to the nearest 1000 for Gbps. E.g.: For 1 Gbps connection, enter 1000 Mbps.

- `GatewaySubnet_cidr`: This is the Gateway subnet address space in CIDR notation. If you have an existing 'GatewaySubnet' in your VNET, you may enter a '0' and the terraform script will lookup the information needed to find the information for the subnet. It is recommended that your GatewaySubnet have at least a /27 or larger (/27, /26, /25, etc.) for this inter-connect, especially when deploying a 10 Gbps throughput ExpressRoute circuit. Bear in mind, that there can only be 1 GatewaySubnet per VNET. If you are also planning on connecting your on-premises network to Azure using ExpressRoute/VPN, the recommendation is to carve out a GatewaySubnet that would be sufficient to route traffic to on-prem and to OCI. See this [link](https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpn-gateway-settings#requirements) for more details.

# Resources

Azure Terraform Provider Documentation -> [https://www.terraform.io/docs/providers/azurerm](https://www.terraform.io/docs/providers/azurerm)
