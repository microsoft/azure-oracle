terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.52"
    }
  }
}
provider "azurerm" {
    features {} 
}

resource "azurerm_resource_group" "oracle_resource_group" {
  name     = "oracle-${var.location}-rg"
  location = var.location
  tags     = var.tags
}

module "vnet" {
  source = "../../../../modules/networking/vnet"
  resource_group_name = azurerm_resource_group.oracle_resource_group.name
  location            = var.location
  vnet_name             = var.vnet_name
  address_space         = var.vnet_address_space
  default_subnet_prefixes = [var.vnet_default_subnet]
  dns_servers = var.dns_servers
  route_table_add=false
}

module "vnet_shared_subnet"{
  source = "../../../../modules//networking/subnet"
  resource_group_name = azurerm_resource_group.oracle_resource_group.name
  vnet_name = module.vnet.vnet_name
  location = var.location
  subnet_name = var.shared_subnet_name
  subnet_prefixes = [var.shared_subnet_addr]
}

module "shared_keyvault_dns_zone"{
  source = "../../../../modules//private_dns/zone"
  resource_group_name = azurerm_resource_group.oracle_resource_group.name
  zone_name =  "privatelink.vaultcore.azure.net"
}

module "keyvault" {
    source  = "../../../../modules/key_vault"
    resource_group_name = azurerm_resource_group.oracle_resource_group.name
    location = var.location
    keyvault_name  = var.key_vault_name
    shared_subnetid  = module.vnet_shared_subnet.subnet_id
    keyvault_zone_name = module.shared_keyvault_dns_zone.dns_zone_name
    keyvault_zone_id = module.shared_keyvault_dns_zone.dns_zone_id
}

module "oracle_vm" { 
    source = "../../../../modules/oracle_virtual_machine"
    resource_group_name = azurerm_resource_group.oracle_resource_group.name
    location = var.location
    vm_name = var.vm_name
    vm_private_ip_addr = var.vm_private_ip_addr
    vm_size = var.vm_size
    subnet_id = module.vnet.default_subnet_id
    vm_admin_username = var.admin_username
    enable_accelerated_networking = var.enable_accelerated_networking
    grid_password = var.grid_password
    oracle_password = var.oracle_password
    root_password = var.root_password
    swap_size = var.swap_size
    grid_storage_url = var.grid_storage_url
    ora_sys_password = var.ora_sys_password
    ora_system_password = var.ora_system_password
    ora_monitor_password = var.ora_monitor_password
    oracle_database_name= var.oracle_database_name
}

module "data_disks"{
    source = "../../../../modules/managed_disk"
    resource_group_name = azurerm_resource_group.oracle_resource_group.name
    vm_name = module.oracle_vm.vm_name
    location = var.location
    storage_account_type = var.storage_account_type
    disk_prefix = var.data_disk_prefix
    disk_size_gb = var.data_disk_size
    disk_count = var.data_disk_count
    disk_cache_type = var.data_disk_cache
    vm_lun_start = var.data_lun_start
    depends_on = [
      module.oracle_vm,
    ]
}

module "redo_disks"{
    source = "../../../../modules/managed_disk"
    resource_group_name = azurerm_resource_group.oracle_resource_group.name
    vm_name = module.oracle_vm.vm_name
    location = var.location
    storage_account_type = var.storage_account_type
    disk_prefix = var.redo_disk_prefix
    disk_size_gb = var.redo_disk_size
    disk_count = var.redo_disk_count
    disk_cache_type = var.redo_disk_cache
    vm_lun_start = var.redo_lun_start
    depends_on = [
      module.oracle_vm,
    ]
}

module "asm_disks"{
    source = "../../../../modules/managed_disk"
    resource_group_name = azurerm_resource_group.oracle_resource_group.name
    vm_name = module.oracle_vm.vm_name
    location = var.location
    storage_account_type = var.storage_account_type
    disk_prefix = var.asm_disk_prefix
    disk_size_gb = var.asm_disk_size
    disk_count = var.asm_disk_count
    disk_cache_type = var.asm_disk_cache
    vm_lun_start = var.asm_lun_start
    depends_on = [
      module.oracle_vm,
    ]
}

resource "azurerm_key_vault_secret" "ora_key" {
  name         = "prikey-oracle"
  value        = module.oracle_vm.tls_private_key 
  key_vault_id = module.keyvault.vault_id
}

module "bastion_region1" {
  source = "../../../../modules/azure_bastion"
  resource_group_name  = azurerm_resource_group.oracle_resource_group.name
  location = var.location
  azurebastion_name = var.azurebastion_name
  azurebastion_vnet_name = module.vnet.vnet_name
  azurebastion_addr_prefix = var.bastion_addr_prefix
}


