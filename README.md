# Azure-OCI Cloud Inter-Connect

[Microsoft and Oracle’s cloud interoperability](https://news.microsoft.com/2019/06/05/microsoft-and-oracle-to-interconnect-microsoft-azure-and-oracle-cloud/) enables you to migrate and run mission-critical enterprise workloads across Microsoft Azure and Oracle Cloud Infrastructure. Run your Oracle database and enterprise applications—including JD Edwards EnterpriseOne, E-Business Suite, PeopleSoft, Oracle Retail, and WebLogic Server—on Oracle Linux, Windows Server, and other supported operating systems in Azure.

## Introduction

This repository contains terraform modules to deploy Azure-OCI Inter-connect as well as the infrastructure for Oracle applications. 

The repository contains modules for deploying the inter-connect between Microsoft Azure & OCI. The deployment is broken into two steps:

- [**InterConnect-1:**](/InterConnect-1) This is the first step to establishing inter-connectivity.
- [**InterConnect-2:**](/InterConnect-2) Once the connection between Oracle and Azure is setup, use this module to setup the connection to your Azure VNET and OCI VCN.

> **NOTE**: Currently, the inter-connect is available available in the Azure's **East US** region and OCI's **Ashburn** region. Additional regions will be added in the future.

In the near future, this repository will contain modules for deploying the infrastructure (reference architecture) for the following Oracle applications:

- [**Oracle E-Business Suite**](https://www.oracle.com/applications/ebusiness/)
- [**JD Edwards EnterpriseOne**](https://www.oracle.com/applications/jd-edwards-enterpriseone/)
- [**Oracle Retail Merchandising System**](https://www.oracle.com/industries/retail/products/merchandise-management/merchandising-system/)
- [**PeopleSoft**](https://www.oracle.com/applications/PEOPLESOFT/)

> **NOTE:** This terraform scripts for Oracle applications provision only the infrastructure required to host the application. The scripts DO NOT install the application itself.

## Repository Structure

- [InterConnect-1](/InterConnect-1) => Contains the first set of terraform scripts to provision the Azure-OCI Cross-Cloud Interconnect
- [InterConnect-2](/InterConnect-2) => Contains modules for the second step to provisioning the inter-connect.

**Future**:
- JDEdwards => Scripts to provision the infrastructure for Oracle JDEdwards application
- EBusinessSuite => Scripts to provision the infrastructure for Oracle E-Business Suite
- Retail => Scripts to provision the infrastructure for Oracle Retail Merchandising Suite
- PeopleSoft => Scripts to provision the infrastructure for Oracle Peoplesoft application

## Getting Started

To deploy Oracle Applications on the Cross-Cloud inter-connect, you will first need the inter-connect provisioned. Follow the steps listed in the README for [InterConnect-1](/InterConnect-1) followed by [InterConnect-2](/InterConnect-2) to deploy the inter-connect. Once the inter-connect has been deployed, you can deploy an application on that inter-connect using the application specific terraform modules here. Follow the instructions and guidance detailed in the README file for each application.
> **Note**: For Oracle applications, only infrastructure deployment can be automated using these terraform scripts. To install the specific application on the deployed infrastructure, please refer to the installation guide for that application.

## Learn More

- [Oracle Workloads on Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/oracle/oracle-overview)
- [Microsoft and Oracle's Partnership Announcement](https://news.microsoft.com/2019/06/05/microsoft-and-oracle-to-interconnect-microsoft-azure-and-oracle-cloud/)
- [Overview of Azure-OCI Inter-connect](https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/oracle/oracle-oci-overview)

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Asking Questions & Reporting Issues

Please create an issue to ask a question or to report a bug/feature request.

## License

Copyright (c) Microsoft Corporation. All rights reserved.

Licensed under the [MIT License](/LICENSE).
