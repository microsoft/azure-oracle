# Defining IP Address Range for the subnets # TODO: Verify this and VNET CIDR wih Karthik
locals {
    bastion_subnet_prefix = "${cidrsubnet(var.vnet_cidr, 3, 0)}"
    admin_subnet_prefix = "${cidrsubnet(var.vnet_cidr, 3, 1)}"
    presentation_subnet_prefix = "${cidrsubnet(var.vnet_cidr, 3, 2)}"
    middle_tier_subnet_prefix = "${cidrsubnet(var.vnet_cidr, 3, 3)}"
    db_tier_subnet_prefix = "${cidrsubnet(var.vnet_cidr, 3, 4)}"
    gateway_subnet_prefix = "${cidrsubnet(var.vnet_cidr, 3, 5)}"    #For VNET Gateway for VPN
    bastion_nsg_name = "bastion_subnet_nsg"
    admin_nsg_name = "admin_subnet_nsg"
    presentation_nsg_name = "presentation_subnet_nsg"
    middle_tier_nsg_name = "middle_tier_subnet_nsg"
    db_tier_nsg_name = "db_tier_subnet_nsg"
    gateway_nsg_name = "gateway_subnet_nsg"

}

# Create a resource group
resource "azurerm_resource_group" "jde-rg" {
  name     = "${var.resource_group_name}"
  location = "${var.deployment_location}"
}

/*
data "azurerm_virtual_network_gateway" "test" { //Temp: Remove later
    name = "Hub-vNET-ERGW"
    resource_group_name = "vNetTest"
}

data "azurerm_express_route_circuit" "test" {
    name = "AzureOracleCircuit"
    resource_group_name = "AzureOracleCircuit"
} */



# Create the VNET
module "create_vnet" {
    source = "./network/vnet"

    vnet_name = "${var.vnet_name}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    location = "${var.deployment_location}"
    vnet_cidr = "${var.vnet_cidr}"
}

# Create a Subnet for the Bastion Host
module "create_bastion_subnet" {
    source = "./network/subnet"

    subnet_name = "bastion"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    vnet_name = "${module.create_vnet.vnet_name}"
    subnet_cidr = "${local.bastion_subnet_prefix}"
}

# Create Admin Tier Subnet
module "create_admin_tier_subnet" {
    source = "./network/subnet"
   
    subnet_name = "admin_tier"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    vnet_name = "${module.create_vnet.vnet_name}"
    subnet_cidr = "${local.admin_subnet_prefix}"
}

# Create Presentation Tier Subnet
module "create_presentation_tier_subnet" {
    source = "./network/subnet"

    subnet_name = "presentation_tier"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    vnet_name = "${module.create_vnet.vnet_name}"
    subnet_cidr = "${local.presentation_subnet_prefix}"
}

# Create Middle Tier Subnet
module "create_middle_tier_subnet" {
    source = "./network/subnet"

    subnet_name = "middle_tier"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    vnet_name = "${module.create_vnet.vnet_name}"
    subnet_cidr = "${local.middle_tier_subnet_prefix}"
}

# TODO: Need a version with Oracle DB in OCI
module "create_db_tier_subnet" {
    source = "./network/subnet"

    subnet_name = "database_tier"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    vnet_name = "${module.create_vnet.vnet_name}"
    subnet_cidr = "${local.db_tier_subnet_prefix}"
}

# Create a GateWay Subnet for VPN
module "create_VPN_GatewaySubnet" {
    source = "./network/subnet"

    subnet_name = "GatewaySubnet"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    vnet_name = "${module.create_vnet.vnet_name}"
    subnet_cidr = "${local.gateway_subnet_prefix}"
}

module "create_ExR_ckt_to_OCI" {
    source = "./network/expressroute"

    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    location = "${var.deployment_location}"
    peering-location = "${var.ExR_peering_location}"
    bandwidth-in-mbps = "${var.ExR_bandwidth_in_mbps}"
}

module "create_virtual_network_ExR_gw" {
    source = "./network/gateway"

    vnet_name = "${module.create_vnet.vnet_name}"
    location = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    gateway-subnet-id = "${module.create_VPN_GatewaySubnet.subnet_id}"
}


# Create NSG for Bastion Subnet
module "bastion_nsg" {
    source = "./network/nsg"
  #  depends_on = ["module.create_bastion_subnet"]

    nsg_name = "${local.bastion_nsg_name}"
    location = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    subnet_id = "${module.create_bastion_subnet.subnet_id}"
}

resource "azurerm_network_security_rule" "nsg_rule_outbound_bastion_subnet" {
    name = "bastion_outbound"
    priority = "100"
    direction = "Outbound"
    access = "Allow"
    protocol = "*"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    network_security_group_name = "${module.bastion_nsg.nsg_name}"
    depends_on = ["module.bastion_nsg"]
}

resource "azurerm_network_security_rule" "nsg_rule_inbound_bastion_subnet" {
    name = "bastion_inbound"
    priority = "101"
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_ranges = ["22", "3389"]
    source_address_prefix = "*"
    destination_address_prefix = "*"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    network_security_group_name = "${module.bastion_nsg.nsg_name}"
    depends_on = ["module.bastion_nsg"]
}


# TODO: If you don't use the securityrule module, clean it up
module "nsg_rule_bastion_subnet" {
    source = "./network/securityrule"

    nsg_rule_name = "bastion_outbound"
    nsg_rule_priority = "100"           #TODO: Check priority of all Sec Rules
    nsg_rule_direction = "Outbound"
    nsg_rule_access = "Allow"
    nsg_rule_protocol = "All"
    nsg_rule_source_port_range = "*"
    nsg_rule_destination_port_range = "*"
    nsg_rule_source_address_prefix = "*"
    nsg_rule_destination_address_prefix = "*" 
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    nsg_name = "${local.bastion_nsg_name}"
    multiple_ports = false
}


# Creating Availability Set for Presentation Tier - JAS
resource "azurerm_availability_set" "bastion_tier_as" {
    name                = "bastion_tier__as"
    location            = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    managed = true
}


module "create_bastion_host" {
    source = "./vm"

    instance_count = 1
    public_ip_name = "bastion_public_ip"
    location = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    nic_name = "bastion_nic"
    nsg_id = "${module.bastion_nsg.nsg_id}"
    ip_config_name = "bastion_ip_config"
    subnet_id = "${module.create_bastion_subnet.subnet_id}"
    vm_name = "BastionHost"
    vm_size = "${var.vm_sku}"
    vm_os_disk_size_in_gb = "60"
    os_publisher = "${var.vm_os_publisher}"
    os_offer = "${var.vm_os_offer}"
    os_sku = "${var.vm_os_sku}"
    os_version = "${var.vm_os_version}"
    vm_admin_username = "${var.vm_admin_username}"
    vm_admin_password = "${var.vm_admin_password}"
    availability_set_id = "${azurerm_availability_set.bastion_tier_as.id}"

    assign_public_ip = true
   # depends_on = ["module.bastion_nsg"]
}


# Creating Availability Set for Admin Tier
resource "azurerm_availability_set" "admin_tier_as" {
    name                = "admin_tier_as"
    location            = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    managed = true
}

# Creating Availability Set for Presentation Tier - JAS
resource "azurerm_availability_set" "presentation_tier_jas_as" {
    name                = "presentation_tier_jas_as"
    location            = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    managed = true
}

# Creating Availability Set for Presentation Tier - AIS
resource "azurerm_availability_set" "presentation_tier_ais_as" {
    name                = "presentation_tier_ais_as"
    location            = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    managed = true
}

# Creating Availability Set for Presentation Tier - Business Services Server
resource "azurerm_availability_set" "presentation_tier_bss_as" {
    name                = "presentation_tier_bss_as"
    location            = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    managed = true
}

# Creating Availability Set for Presentation Tier - Real-time Events Server
resource "azurerm_availability_set" "presentation_tier_rtes_as" {
    name                = "presentation_tier_rtes_as"
    location            = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    managed = true
}

# Creating Availability Set for Presentation Tier - BI Publishing Server
resource "azurerm_availability_set" "presentation_tier_bips_as" {
    name                = "presentation_tier_bips_as"
    location            = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    managed = true
}

# Creating Availability Set for Presentation Tier - ADF Server
resource "azurerm_availability_set" "presentation_tier_adf_as" {
    name                = "presentation_tier_adf_as"
    location            = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    managed = true
} 

# Creating Availability Set for Middle Tier
resource "azurerm_availability_set" "middle_tier_as" {
    name                = "middle_tier_as"
    location            = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    managed = true
} 

# Creating Availability Set for Database Tier
resource "azurerm_availability_set" "db_tier_as" {
    name                = "db_tier_as"
    location            = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    managed = true
} 

# Create NSG for Admin Subnet
module "admin_nsg" {
    source = "./network/nsg"

    nsg_name = "${local.admin_nsg_name}"
    location = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    subnet_id = "${module.create_admin_tier_subnet.subnet_id}"
}

resource "azurerm_network_security_rule" "nsg_rule_outbound_admin_subnet" {
    name = "admin_outbound"
    priority = "100"
    direction = "Outbound"
    access = "Allow"
    protocol = "*"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    network_security_group_name = "${module.admin_nsg.nsg_name}"
    depends_on = ["module.admin_nsg"]
}

resource "azurerm_network_security_rule" "nsg_rule_inbound_admin_subnet" {
    name = "admin_inbound"
    priority = "101"
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_ranges = ["22", "445", "3000", "3389", "5150", "5985", "6017-6022", "7001", "8998", "8999", "14501-14510"] #TODO: Add this to a variable
    source_address_prefix = "${var.vnet_cidr}"
    destination_address_prefix = "*"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    network_security_group_name = "${module.admin_nsg.nsg_name}"
    depends_on = ["module.admin_nsg"]
}

# Create NSG for Presentation Subnet
module "presentation_nsg" {
    source = "./network/nsg"

    nsg_name = "${local.presentation_nsg_name}"
    location = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    subnet_id = "${module.create_presentation_tier_subnet.subnet_id}"
}

resource "azurerm_network_security_rule" "nsg_rule_outbound_presentation_subnet" {
    name = "presentation_outbound"
    priority = "100"
    direction = "Outbound"
    access = "Allow"
    protocol = "*"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    network_security_group_name = "${module.presentation_nsg.nsg_name}"
    depends_on = ["module.presentation_nsg"]
}

resource "azurerm_network_security_rule" "nsg_rule_inbound_presentation_subnet" {
    name = "presentation_inbound"
    priority = "101"
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_ranges = ["22", "5150", "6017-6022", "7001", "8000-8003", "8010-8013", "8020-8023", "8030-8050", "8998", "14501-14520"] #TODO: Add this to a variable. hard-coded for now. Rishi: lbaas_html, etc. how come those are configurable?
    source_address_prefix = "${var.vnet_cidr}"
    destination_address_prefix = "*"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    network_security_group_name = "${module.presentation_nsg.nsg_name}"
    depends_on = ["module.presentation_nsg"]
}

# Create NSG for Middle Tier Subnet
module "middle_tier_nsg" {
    source = "./network/nsg"

    nsg_name = "${local.middle_tier_nsg_name}"
    location = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    subnet_id = "${module.create_middle_tier_subnet.subnet_id}"
}

resource "azurerm_network_security_rule" "nsg_rule_outbound_middle_tier_subnet" {
    name = "middle_tier_outbound"
    priority = "100"
    direction = "Outbound"
    access = "Allow"
    protocol = "*"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    network_security_group_name = "${module.middle_tier_nsg.nsg_name}"
    depends_on = ["module.middle_tier_nsg"]
}

resource "azurerm_network_security_rule" "nsg_rule_inbound_middle_tier_subnet" {
    name = "middle_tier_inbound"
    priority = "101"
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_ranges = ["22", "5150", "6017-6022", "8998", "14501-14510"] #TODO: Add this to a variable. hard-coded for now. Rishi: lbaas_html, etc. how come those are configurable?
    source_address_prefix = "${var.vnet_cidr}"
    destination_address_prefix = "*"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    network_security_group_name = "${module.middle_tier_nsg.nsg_name}"
    depends_on = ["module.middle_tier_nsg"]
}


# Create NSG for GatewaySubnet
module "gateway_nsg" {
    source = "./network/nsg"

    nsg_name = "${local.gateway_nsg_name}"
    location = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    subnet_id = "${module.create_VPN_GatewaySubnet.subnet_id}"
} #TODO: Security rules for GatewaySubnet

# Create NSG for Database Subnet
module "db_nsg" {
    source = "./network/nsg"

    nsg_name = "${local.db_tier_nsg_name}"
    location = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    subnet_id = "${module.create_db_tier_subnet.subnet_id}"
}

resource "azurerm_network_security_rule" "nsg_rule_outbound_db_tier_subnet" {
    name = "db_tier_outbound"
    priority = "100"
    direction = "Outbound"
    access = "Allow"
    protocol = "*"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    network_security_group_name = "${module.db_nsg.nsg_name}"
    depends_on = ["module.db_nsg"]
}

resource "azurerm_network_security_rule" "nsg_rule_inbound_db_tier_subnet" {
    name = "db_tier_inbound"
    priority = "101"
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_ranges = ["22", "1521", "5150", "8998", "14501-14510"] #TODO: Add this to a variable. hard-coded for now. Rishi: lbaas_html, etc. how come those are configurable?
    source_address_prefix = "${var.vnet_cidr}"
    destination_address_prefix = "*"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    network_security_group_name = "${module.db_nsg.nsg_name}"
    depends_on = ["module.db_nsg"]
}

# Creating Admin Tier VMs
module "create_provisioning_server" {
    source = "./vm"
    
    instance_count = "1"
    location = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    nic_name = "ps_nic"
    nsg_id = "${module.admin_nsg.nsg_id}"
    ip_config_name = "jas_ip_config"
    subnet_id = "${module.create_admin_tier_subnet.subnet_id}"
    vm_name = "ProvisioningServer"
    vm_size = "${var.vm_sku}"
    availability_set_id = "${azurerm_availability_set.admin_tier_as.id}"
    vm_os_disk_size_in_gb = "60"
    os_publisher = "${var.vm_os_publisher}"
    os_offer = "${var.vm_os_offer}"
    os_sku = "${var.vm_os_sku}"
    os_version = "${var.vm_os_version}"
    vm_admin_username = "${var.vm_admin_username}"
    vm_admin_password = "${var.vm_admin_password}"
    public_ip_name = "nopublicip"

    assign_public_ip = false
}

module "create_deployment_server" {
    source = "./vm"
    
    instance_count = "1"
    location = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    nic_name = "ds_nic"
    nsg_id = "${module.admin_nsg.nsg_id}"
    ip_config_name = "ds_ip_config"
    subnet_id = "${module.create_admin_tier_subnet.subnet_id}"
    vm_name = "DeploymentServer"
    vm_size = "${var.vm_sku}"
    availability_set_id = "${azurerm_availability_set.admin_tier_as.id}"
    vm_os_disk_size_in_gb = "60"
    os_publisher = "${var.vm_os_publisher}"
    os_offer = "${var.vm_os_offer}"
    os_sku = "${var.vm_os_sku}"
    os_version = "${var.vm_os_version}"
    vm_admin_username = "${var.vm_admin_username}"
    vm_admin_password = "${var.vm_admin_password}"
    public_ip_name = "nopublicip"

    assign_public_ip = false
}

module "create_deployment_center" {
    source = "./vm"
    
    instance_count = "1"
    location = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    nic_name = "dc_nic"
    nsg_id = "${module.admin_nsg.nsg_id}"
    ip_config_name = "dc_ip_config"
    subnet_id = "${module.create_admin_tier_subnet.subnet_id}"
    vm_name = "DevelopmentCenter"
    vm_size = "${var.vm_sku}"
    availability_set_id = "${azurerm_availability_set.admin_tier_as.id}"
    vm_os_disk_size_in_gb = "60"
    os_publisher = "${var.vm_os_publisher}"
    os_offer = "${var.vm_os_offer}"
    os_sku = "${var.vm_os_sku}"
    os_version = "${var.vm_os_version}"
    vm_admin_username = "${var.vm_admin_username}"
    vm_admin_password = "${var.vm_admin_password}"
    public_ip_name = "nopublicip"

    assign_public_ip = false
}

# Creating Presentation Tier VMs
module "create_jas" {
    source = "./vm"
    
    instance_count = "${var.number_of_instances}"
    location = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    nic_name = "jas_nic"
    nsg_id = "${module.presentation_nsg.nsg_id}"
    ip_config_name = "jas_ip_config"
    subnet_id = "${module.create_presentation_tier_subnet.subnet_id}"
    vm_name = "JavaAppServer"
    vm_size = "${var.vm_sku}"
    availability_set_id = "${azurerm_availability_set.presentation_tier_jas_as.id}"
    vm_os_disk_size_in_gb = "60"
    os_publisher = "${var.vm_os_publisher}"
    os_offer = "${var.vm_os_offer}"
    os_sku = "${var.vm_os_sku}"
    os_version = "${var.vm_os_version}"
    vm_admin_username = "${var.vm_admin_username}"
    vm_admin_password = "${var.vm_admin_password}"
    public_ip_name = "nopublicip"

    assign_public_ip = false
}

module "create_ais" {
    source = "./vm"
    
    instance_count = "${var.number_of_instances}"
    location = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    nic_name = "ais_nic"
    nsg_id = "${module.presentation_nsg.nsg_id}"
    ip_config_name = "ais_ip_config"
    subnet_id = "${module.create_presentation_tier_subnet.subnet_id}"
    vm_name = "AppInterfaceServicesServer"
    vm_size = "${var.vm_sku}"
    availability_set_id = "${azurerm_availability_set.presentation_tier_ais_as.id}"
    vm_os_disk_size_in_gb = "60"
    os_publisher = "${var.vm_os_publisher}"
    os_offer = "${var.vm_os_offer}"
    os_sku = "${var.vm_os_sku}"
    os_version = "${var.vm_os_version}"
    vm_admin_username = "${var.vm_admin_username}"
    vm_admin_password = "${var.vm_admin_password}"
    public_ip_name = "nopublicip"

    assign_public_ip = false
}

module "create_bss" {
    source = "./vm"
    
    instance_count = "${var.number_of_instances}"
    location = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    nic_name = "bss_nic"
    nsg_id = "${module.presentation_nsg.nsg_id}"
    ip_config_name = "bss_ip_config"
    subnet_id = "${module.create_presentation_tier_subnet.subnet_id}"
    vm_name = "BusinessServicesServer"
    vm_size = "${var.vm_sku}"
    availability_set_id = "${azurerm_availability_set.presentation_tier_bss_as.id}"
    vm_os_disk_size_in_gb = "60"
    os_publisher = "${var.vm_os_publisher}"
    os_offer = "${var.vm_os_offer}"
    os_sku = "${var.vm_os_sku}"
    os_version = "${var.vm_os_version}"
    vm_admin_username = "${var.vm_admin_username}"
    vm_admin_password = "${var.vm_admin_password}"
    public_ip_name = "nopublicip"

    assign_public_ip = false
}

module "create_rtes" {
    source = "./vm"
    
    instance_count = "${var.number_of_instances}"
    location = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    nic_name = "rtes_nic"
    nsg_id = "${module.presentation_nsg.nsg_id}"
    ip_config_name = "rtess_ip_config"
    subnet_id = "${module.create_presentation_tier_subnet.subnet_id}"
    vm_name = "RealTimeEventsServer"
    vm_size = "${var.vm_sku}"
    availability_set_id = "${azurerm_availability_set.presentation_tier_rtes_as.id}"
    vm_os_disk_size_in_gb = "60"
    os_publisher = "${var.vm_os_publisher}"
    os_offer = "${var.vm_os_offer}"
    os_sku = "${var.vm_os_sku}"
    os_version = "${var.vm_os_version}"
    vm_admin_username = "${var.vm_admin_username}"
    vm_admin_password = "${var.vm_admin_password}"
    public_ip_name = "nopublicip"

    assign_public_ip = false
}

module "create_bips" {
    source = "./vm"
    
    instance_count = "${var.number_of_instances}"
    location = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    nic_name = "bips_nic"
    nsg_id = "${module.presentation_nsg.nsg_id}"
    ip_config_name = "bips_ip_config"
    subnet_id = "${module.create_presentation_tier_subnet.subnet_id}"
    vm_name = "BIPublisherServer"
    vm_size = "${var.vm_sku}"
    availability_set_id = "${azurerm_availability_set.presentation_tier_bips_as.id}"
    vm_os_disk_size_in_gb = "60"
    os_publisher = "${var.vm_os_publisher}"
    os_offer = "${var.vm_os_offer}"
    os_sku = "${var.vm_os_sku}"
    os_version = "${var.vm_os_version}"
    vm_admin_username = "${var.vm_admin_username}"
    vm_admin_password = "${var.vm_admin_password}"
    public_ip_name = "nopublicip"

    assign_public_ip = false
}

module "create_adf" {
    source = "./vm"
    
    instance_count = "${var.number_of_instances}"
    location = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    nic_name = "adf_nic"
    nsg_id = "${module.presentation_nsg.nsg_id}"
    ip_config_name = "adf_ip_config"
    subnet_id = "${module.create_presentation_tier_subnet.subnet_id}"
    vm_name = "ADFServer"
    vm_size = "${var.vm_sku}"
    availability_set_id = "${azurerm_availability_set.presentation_tier_adf_as.id}"
    vm_os_disk_size_in_gb = "60"
    os_publisher = "${var.vm_os_publisher}"
    os_offer = "${var.vm_os_offer}"
    os_sku = "${var.vm_os_sku}"
    os_version = "${var.vm_os_version}"
    vm_admin_username = "${var.vm_admin_username}"
    vm_admin_password = "${var.vm_admin_password}"
    public_ip_name = "nopublicip"

    assign_public_ip = false
}

# Creating Middle Tier VMs

module "create_middle_tier" {
    source = "./vm"
    
    instance_count = "${var.number_of_instances}"
    location = "${var.deployment_location}"
    resource_group_name = "${azurerm_resource_group.jde-rg.name}"
    nic_name = "middle_tier_nic"
    nsg_id = "${module.middle_tier_nsg.nsg_id}"
    ip_config_name = "middle_tier_ip_config"
    subnet_id = "${module.create_middle_tier_subnet.subnet_id}"
    vm_name = "MiddleTierServer"
    vm_size = "${var.vm_sku}"
    availability_set_id = "${azurerm_availability_set.middle_tier_as.id}"
    vm_os_disk_size_in_gb = "60"
    os_publisher = "${var.vm_os_publisher}"
    os_offer = "${var.vm_os_offer}"
    os_sku = "${var.vm_os_sku}"
    os_version = "${var.vm_os_version}"
    vm_admin_username = "${var.vm_admin_username}"
    vm_admin_password = "${var.vm_admin_password}"
    public_ip_name = "nopublicip"

    assign_public_ip = false
}

# Create DB Tier
/*
module "create_db_tier" {
    source = "./db"

    
}*/