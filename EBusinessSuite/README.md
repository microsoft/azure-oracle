# E-Business Suite Application

## Introduction

This terraform template allows you to setup the infrastructure of the E-Business Suite application. Once the application setup is complete, you may install the application using the guide provided by Oracle [#TODO: Need link to installation guide]

## Instructions

### Setup the Terraform scripts

1. If you haven't already done so in this terminal session, Open the file [env_vars](./../env_vars) (or [env_vars.ps1](./../env_vars.ps1) if you do not have the Windows Sub-system for Linux (WSL) or GitBash installed). Add the details regarding your Azure account. 

1. In order to execute terraform scripts in Azure, you will need to use a Azure AD Service principal and grant it the necessary permissions to create and delete resources in your Azure subscription. You can find more details on achieving this can be found here: [Terraform Azure Provider: Authenticating using a Service Principal with a Client Secret](https://www.terraform.io/docs/providers/azurerm/auth/service_principal_client_secret.html). Alternate options to authenticating with Terraform can also be found in that link. You may need to modify the **provider.tf** file in order to use these alternate ways of authentication.

1. Save the file and close it.

1. Execute the following command from your shell and naviagate to the root folder and execute following command:
    - (For Linux or WSL/GitBash) `$ source env-vars`
    - (For Older versions of Windows) `> env-vars.ps1`

1. Open the [ebs_input.json](./input/ebs_input.json) file and fill in the information as required. Details regarding what information is expected can be found [below](#terraformvariables). Save and close the file.

1. From the terminal, navigate to the `EBusinessSuite` folder (if you haven't already) and run a terraform init command:
    
    `$ terraform init`

1. You should see the following output:

    {#TODO: Need Image}

1. Next, run the `terraform apply` command as follows:

    `$ terraform apply -var-file ./input/ebs_input.json`

1. This will create the required Azure resources. You will see the output as follows.

    {#TODO: Need Image}

### Previous Notes (Please ignore)

@REM Use these variables for a quick run of EBS main.tf
@REM ============================================================
@REM  You need to authentication using the CLI before 
@REM  running Terraform plan or apply.  e.g.,
@REM    az login
@REM    az account set --subscription 999902f0-e209-4f0d-a253-4b86032eac0e
@REM
@REM ============================================================
@REM The following are likely to need modification for your testing.
@REM The tenant ID will be returned in the "az login" result above.
@REM
SET TF_VAR_subscription_id=999902f0-e209-4f0d-a253-4b86032eac0e
SET TF_VAR_tenant_id=72f988bf-aaaa-41af-91ab-2d7cd011db47
@REM
@REM SSH settings for the VMs
@REM The templates expect that you'll have a key file (defaulting to the same 
@REM  "~/.ssh/id_rsa.pub" for both bastion and others).  If you want to override
@REM  the path(es) define the following variables to point to the desired file(s).
@REM
@REM SET TF_VAR_compute_ssh_public_key=c:/users/%USERNAME%/documents/Test1.public.ppk
@REM SET TF_VAR_bastion_ssh_public_key=c:/users/%USERNAME%/documents/Test1.public.ppk
@REM
@REM ============================================================
@REM ==  Items below here will likely not require adjustment to execute the templates.
@REM
@REM  The script will push in some data via CustomData.  For now, this can be anything.
SET TF_VAR_custom_data=#!/bin/sh
@REM
SET TF_VAR_client_id=abc
SET TF_VAR_client_secret=def
@REM Image selection for the Application and Bastion
SET TF_VAR_vm_os_offer=abc
SET TF_VAR_vm_os_publisher=abc
SET TF_VAR_vm_os_sku=abc
SET TF_VAR_vm_os_version=abc
SET TF_VAR_vm_sku=Standard_DS1_v2
SET TF_VAR_environment=test
SET TF_VAR_number_of_instances=2
@REM
@REM Image selection for the database VM
SET TF_VAR_db_offer=abc
SET TF_VAR_db_publisher=abc
SET TF_VAR_db_sku=abc
SET TF_VAR_db_version=abc
@REM
@REM currently VMs are only SSH access, but user/pw included for now.
SET TF_VAR_admin_password=!!abc9545ABC9545
SET TF_VAR_admin_username=cuser
@REM Housekeeping
SET TF_VAR_resource_group_name="AAA5"
SET TF_VAR_location="EastUS"
@REM
@REM Network config
SET TF_VAR_vnet_cidr=10.0.0.0/16
SET TF_VAR_vnet_name=EBSVN3
@REM
@REM Finis