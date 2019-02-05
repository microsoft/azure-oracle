resource "null_resource" "remote-exec" {
        count = "${var.instance_count}"
	depends_on = ["azure_core_instance.tf_web","azure_core_volume_attachment.tf_web_attach"]
	provisioner "file" {
		connection {
			agent = false
			timeout = "10m"
			host = "${azure_core_instance.tf_web.*.public_ip}"
			user = "opc"
			private_key = "${file(var.ssh_private_key)}"
		}
        source = "${path.module}/wlsinstall/"
        destination = "${var.unix_mount_directory}/jde_tf/wlsinstall"
}


	provisioner "file" {
               connection {
                        agent = false
                        timeout = "10m"
                        host = "${azure_core_instance.tf_web.*.public_ip}"
                        user = "opc"
                        private_key = "${file(var.ssh_private_key)}"
                }
        source = "${path.module}/wlsbinary/"
        destination = "${var.unix_mount_directory}/jde_tf/wlsbinary"
}


	provisioner "remote-exec" {
             connection {
                        agent = false
                        timeout = "10m"
                        host = "${azure_core_instance.tf_web.*.public_ip}"
                        user = "opc"
                        private_key = "${file(var.ssh_private_key)}"
                }
   	 inline = [
      		"sudo chmod -R 777 ${var.unix_mount_directory}/jde_tf/*",
		"${var.unix_mount_directory}/jde_tf/wlsinstall/deploywls.sh ${var.JDK_INSTALL_BINARY_NAME} ${var.WLS_INSTALL_BINARY_NAME} ${var.WLS_PSWD} ${var.unix_mount_directory}"
    ]
  }
}
