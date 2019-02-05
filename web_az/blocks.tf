# Using availability sets instead of zones 
resource "azurerm_core_volume" "web_block" {
  name     = "jdeweb"
  location = "East US"
}

resource "azurerm_availability_set" "web_block" {
  name                = "acceptanceTestAvailabilitySet1"
  location            = "${azurerm_core_volume.web_block.location}"
  resource_group_name = "${azurerm_core_volume.web_block.name}"

  tags {
    environment = "Production"
  }
}

resource "azure_core_volume_attachment" "tf_web_attach" {
    attachment_type = "iscsi"
    count = "${length(var.unix_mount_directory) > 1 ? var.instance_count : 0 }",
    compartment_id = "${var.compartment_name}"
    instance_id = "${element(azure_core_instance.tf_web.*.id, count.index)}" 
    volume_id = "${element(azurerm_core_volume.web_block.*.id, count.index)}"
    
       provisioner "remote-exec" {
      connection {
        agent = false
        host = "${element(azure_core_instance.tf_web.*.public_ip, count.index)}"
        user = "opc"
        private_key = "${file(var.ssh_private_key)}"
    }
    inline = [
		"sudo service iscsi reload",
                "sudo -s bash -c 'iscsiadm -m node -o new -T ${self.iqn} -p ${self.ipv4}:${self.port}'",
                "sudo -s bash -c 'iscsiadm -m node -o update -T ${self.iqn} -n node.startup -v automatic '",
                "sudo -s bash -c 'iscsiadm -m node -T ${self.iqn} -p ${self.ipv4}:${self.port} -l '",
                "sudo -s bash -c 'mkfs.ext4 -F /dev/sdb'",
                "sudo -s bash -c 'mount -t ext4 /dev/sdb ${var.unix_mount_directory}'",
                "sudo -s bash -c 'echo \"/dev/sdb ${var.unix_mount_directory} ext4 defaults,noatime,_netdev,nofail 0 2\" >> /etc/fstab'",
                "sudo -s bash -c 'chown -R opc:opc ${var.unix_mount_directory}'",
                "sudo -s bash -c 'chmod 775 ${var.unix_mount_directory}'",
                "sudo -s bash -c 'chgrp oracle ${var.unix_mount_directory}'",
                "sudo mkdir -p ${var.unix_mount_directory}/jde_tf/wlsinstall",
                "sudo mkdir -p ${var.unix_mount_directory}/jde_tf/wlsbinary",
                "sudo mkdir -p ${var.unix_mount_directory}/jde_tf/wlsinstall/templates",
                "sudo chmod -R 777 ${var.unix_mount_directory}/jde_tf"
    ]
  }
}
