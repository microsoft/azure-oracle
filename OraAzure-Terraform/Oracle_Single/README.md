# Oracle StandAlone database deployment
Terraform deployment to build a Azure virtual machine by passing variables to allow for a dynamic build.  Intent is to give flexibility to the engineer to pick a vm size and disk configuration and automatically deploy the oracle database fully configured.  Disk configuration includes size, number of disks, type of disks, and caching for disks.   

# Dependencies
Engineer deploying needs to have the following:
1. [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/azure-get-started)
3. [Visual Studio Code](https://code.visualstudio.com/)
4. [Clone of GitHub Repo](https://github.com/aultt/Azure-Terraform-LabinaBox) 
6. Download of [Grid Infrastructure](https://www.oracle.com/database/technologies/oracle19c-linux-downloads.html) stored into an Azure Storage Account.  
7. Creation of a SAS token to leverage file referenced above.

# Build and Test
Prior to deploying the Oracle you will want to look over and confirm/modify variables within the deployment.  

## Template Variable File
A Sample variable file has been provided with the required variables which should be configured.  Variable file is named oracle_template.tfvars.  Any additional variables you would like to change can be added to this file. Once updated you can run the following: terraform init -var-file=oracle_template.tfvars followed by terraform apply -var-file=oracle_template.tfvars. Its recommended to create a copy of the variables file and change the template to your name or something else to identify it.  This will prevent it from be merged back to github as there is an ignore for all other .tvars files.  After Terraform has been deployed there is an additional step to deploy the oracle configuration.  Connect to the VM with Bastion, which was created as part of the deployment.  If you accepted the defaults the username is azureadmin, for authentication select SSH Private Key from Azure Key Vault.  The Subscription, KevVault and Secret should auto-select.  Click Connect.  You should now be in the VM.  Type ls, you should see two files in your home directory, Configure-ASM-server.yml and deployoracle.sh.  The yml file is the ansible playbook while the sh file is the command with required parameters to deploy the playbook.  Execute by typing . ./deployoracle.sh the playbook will deploy oracle and should complete in around 15min.  You are now ready to connect to oracle run some tests or create tables.

## Variables which must be updated
1. grid_password
2. oracle_password
3. root_password
4. oracle_sys_password
5. oracle_system_password
6. oracle_monitor_password

## Variables which can be updated if you deviated from default
1. vnet_name                default: vnet-lz-spk-eastus2
2. key_vault_name           default: kv-labiac-eastus2
3. location                 default: eastus2
7. admin_username           default: azureadmin
8. vm_name                  default: oracledev01 
9. vm_private_ip_addr       default: 10.1.1.15
10. oracle_database_name    default: mytestdb

## Variables which can be updated for different performance tests
1.  vm_size                 default: Standard_DS11_v2
2.  asm_disk_size           default: 64
3.  asm_lun_start           default: 10
4.  asm_disk_count          default: 1
5.  asm_disk_cache          default: ReadWrite
6.  asm_disk_prefix         default: asm-disk
7.  data_disk_size          default: 512
8.  data_lun_start          default: 20
9.  data_disk_count         default: 2
10. data_disk_cache         default: ReadOnly
11. data_disk_prefix        default: data-disk
12. redo_disk_size          default: 128
13. redo_lun_start          default: 60
14. redo_disk_count         default: 2
15. redo_disk_cache         default: ReadWrite
16. redo_disk_prefix        default: redo-disk
17. storage_account_type    default: StandardSSD_LRS

## TODO Items: 
Within the Ansible yml there are TODO tags of items which could be made variables or addressed, however have not been done.  They are documented below for future reference.
1. While there is a variable for lun start its currently not leveraged everywhere.  Disk discovery is done based on lun number. Currently hardcoded in ansible for the following:
    ASM     lun 10-19
    Data    lun 20-59
    Redo    lun 60-69
If there is a need for more disks for either these will need to be manually adjusted. Lines 73 - 84 of Configure-ASM-server.yml to be specific.
2. Linux Swap Size is currently set to 13435 as a variable which is the correct swap size for the virtual machine image which is set as default.  If Vm image is changed this variable also needs to be updated to reflect the correct swap size.
3. Several of the configurations required by oracle require shell scripts to execute oracle commands.  As a result some of these commands can only be run once.  Commands should be augmented with checks before they run which would make the terraform and ansible re-runnable.  Lines referenced are the following 206 and 222 - 245.
4. ASM disk count.  If you pass a disk count greater than 1 Terraform will create the additional disks, however oracle will only configure the first disk in the disk pool.  To address this the response file would need to have each disk added by with its full path.


