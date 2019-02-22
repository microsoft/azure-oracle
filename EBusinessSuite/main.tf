locals {
  // VNET is /16
  subnet_bits = 8   # want 256 entries per subnet.
  vnet_cidr_increase = "${32 - element(split("/",var.vnet_cidr),1) - local.subnet_bits}"
  bastion_subnet_prefix = "${cidrsubnet("${var.vnet_cidr}", 6, 0)}"
  lb_subnet_prefix      = "${cidrsubnet("${var.vnet_cidr}", 6, 1)}"
  app_subnet_prefix     = "${cidrsubnet("${var.vnet_cidr}", 6, 2)}"
  db_subnet_prefix      = "${cidrsubnet("${var.vnet_cidr}", 6, 3)}"
}
# Create Resource Group
resource "azurerm_resource_group" "ebs-rg" {
    name     = "${var.resource_group_name}"
    location = "${var.location}"
 }

# Create Virtual Network (VNET)
module "create_vnet" {
  source  = "./modules/network/vnet"

  resource_group_name    = "${azurerm_resource_group.ebs-rg.name}"
  location               = "${var.location}"
  vnet_cidr              = "${var.vnet_cidr}"
  vnet_name              = "${var.vnet_name}"
}

# Create bastion host subnet
module "bastion_subnet" {
  source  = "./modules/network/subnets"

  resource_group_name    = "${azurerm_resource_group.ebs-rg.name}"
  vnet_name            = "${module.create_vnet.vnet_name}"
  subnet_cidr_map      =  {bastion = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 1)}"}
  
}
# Create Application subnet
module "app_subnet" {
  source  = "./modules/network/subnets"

  resource_group_name    = "${azurerm_resource_group.ebs-rg.name}"
  vnet_name            = "${module.create_vnet.vnet_name}"
  subnet_cidr_map      =  {application = "${cidrsubnet(var.vnet_cidr, local.vnet_cidr_increase, 2)}"}
}

/* 
# Create bastion host
module "create_bastion" {
  source  = "./modules/bastion"

  compartment_ocid        = "${var.compartment_ocid}"
  AD                      = "${var.AD}"
  availability_domain     = ["${data.template_file.deployment_ad.*.rendered}"]
  bastion_hostname_prefix = "${var.ebs_env_prefix}bas${substr(var.region, 3, 3)}"
  bastion_image           = "${data.oci_core_images.InstanceImageOCID.images.0.id}"
  bastion_instance_shape  = "${var.bastion_instance_shape}"
  bastion_subnet          = ["${module.bastion_subnet.subnetid}"]
  bastion_ssh_public_key  = "${var.bastion_ssh_public_key}"
  }
 */
# Create Application server
module "create_app" {
  source  = "./modules/compute"

  vm_hostname               = "${var.vm_hostname}"
  resource_group_name    = "${azurerm_resource_group.ebs-rg.name}"
  location                  = "${var.location}"
  tags                      = "${var.tags}"
  compute_hostname_prefix   = "${var.compute_hostname_prefix}"
  compute_instance_count    = "${var.compute_instance_count}"
  vm_size                   = "${var.vm_size}"
  os_publisher              = "${var.os_publisher}"   
  os_offer                  = "${var.os_offer}"
  os_sku                    = "${var.os_sku}"
  os_version                = "${var.os_version}"
  storage_account_type      = "${var.storage_account_type}"
  compute_boot_volume_size_in_gb    = "${var.compute_boot_volume_size_in_gb}"
  data_disk_size_gb         = "${var.data_disk_size_gb}"
  data_sa_type              = "${var.data_sa_type}"
  admin_username            = "${var.admin_username}"
  admin_password            = "${var.admin_password}"
  custom_data               = "${var.custom_data}"
  compute_ssh_public_key    = "${var.compute_ssh_public_key}"
  enable_accelerated_networking     = "${var.enable_accelerated_networking}"
  vnet_subnet_id            = "${element(values(module.app_subnet.subnet_ids), 0)}"
  backendpool_id            = "${module.ebslb.backendpool_id}"
  #TODO network_security_group_id = "${module.app_nsg.nsg_id}"
}

# Create Load Balancer
module "ebslb" {
  source              = "./modules/load balancer"
  resource_group_name    = "${azurerm_resource_group.ebs-rg.name}"
  location            = "${var.location}"
  prefix              = "ebs"
  lb_sku              = "${var.lb_sku}"
  frontend_subnet_id  = "${element(values(module.app_subnet.subnet_ids), 0)}"
  tags                = "${var.tags}"

  "lb_port" {
    http = ["8080", "Tcp", "8888"]
  }
}
