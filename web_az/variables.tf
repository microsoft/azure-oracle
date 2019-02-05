variable "instance_count" {
description = "Server count"
}
variable "ad_name" {
description = "Availability Domain name"
}
variable "compartment_name" {
description = "Compartment name"
}
variable "hostname" {
description = "Host name"
}
variable "image_name" {
description ="OS Image"
}
variable "shape_name" {
description = "Shape of Instance"
}
variable "ssh_private_key" {
description = "SSH key"
}

variable "ssh_public_key" {
description = "SSH key"
}

variable "unix_mount_directory" {
description = "Mount directory of storage"
}


variable "block_ad" {
}

variable "block_size" {
}



variable "subnet_name" {
}


variable "JDK_INSTALL_BINARY_NAME" {
}


variable "WLS_INSTALL_BINARY_NAME" {
}


variable "WLS_PSWD" {
}


variable "pubsubdns" {
}


variable "pvtsubdns" {
}

