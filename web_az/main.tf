resource "azure_core_instance" "tf_web" {

  count = "${var.instance_count}"
  availability_domain = "${var.ad_name}"
  compartment_id = "${var.compartment_name}"
  display_name = "${var.hostname}c${count.index+1}"
  hostname_label = "${var.hostname}c${count.index+1}"
  image = "${var.image_name}"
  shape = "${var.shape_name}"
  subnet_id = "${var.subnet_name}"
  metadata {
    ssh_authorized_keys = "${file(var.ssh_public_key)}"
  }

    provisioner "remote-exec" {
      connection {
        host = "${self.public_ip}"
        user = "opc"
        private_key = "${file(var.ssh_private_key)}"
    }
    inline = [
     "sudo service ipchains stop",
      "sudo service iptables stop",
      "sudo chkconfig ipchains off",
      "sudo chkconfig iptables off",
      "sudo systemctl stop firewalld.service",
      "sudo systemctl disable firewalld.service",
      "sudo yum -y install zip.x86_64",
      "sudo yum -y install unzip.x86_64",
      "sudo yum -y install ruby.x86_64",
      "sudo yum -y install ruby-devel.x86_64",
      "sudo yum -y install samba.x86_64",
      "sudo yum -y install samba-client.x86_64",
      "sudo yum -y install gcc-c++.x86_64",
      "sudo yum -y install gcc.x86_64",
      "sudo yum -y install zlib-devel.x86_64",
      "sudo yum -y install compat-libcap1.x86_64",
      "sudo yum -y install compat-libstdc++-33.x86_64",
      "sudo yum -y install elfutils-libelf-devel.x86_64",
      "sudo yum -y install glibc.x86_64",
      "sudo yum -y install glibc-devel.x86_64",
      "sudo yum -y install nmap.x86_64",
      "sudo yum -y install glibc-devel.x86_64",
      "sudo yum -y install libaio.x86_64",
      "sudo yum -y install libaio-devel.x86_64",
      "sudo yum -y install libgcc.x86_64",
      "sudo yum -y install libstdc++.x86_64",
      "sudo yum -y install libstdc++-devel.x86_64",
      "sudo yum -y install libX11.x86_64",
      "sudo yum -y install libXau.x86_64",
      "sudo yum -y install libxcb.x86_64",
      "sudo yum -y install libXext.x86_64",
      "sudo yum -y install libXi.x86_64",
      "sudo yum -y install libXtst.x86_64",
      "sudo yum -y install make.x86_64",
      "sudo yum -y install sysstat.x86_64",
      "sudo yum -y install unixODBC-devel.x86_64",
      "sudo yum -y install unixODBC.x86_64",
      "sudo yum -y install zlib-devel.x86_64",
      "sudo yum -y install zlib-devel.i686",
      "sudo yum -y install compat-libstdc++-33.i686",
      "sudo yum -y install glibc.i686",
      "sudo yum -y install glibc-devel.i686",
      "sudo yum -y install libaio.i686",
      "sudo yum -y install libaio-devel.i686",
      "sudo yum -y install libgcc.i686",
      "sudo yum -y install libstdc++.i686",
      "sudo yum -y install libX11.i686",
      "sudo yum -y install libXau.i686",
      "sudo yum -y install libxcb.i686",
      "sudo yum -y install libXext.i686",
      "sudo yum -y install libXi.i686",
      "sudo yum -y install libXtst.i686",
      "sudo yum -y install nss-softokn-freebl.i686",
      "sudo yum -y install zlib.i686",
      "sudo yum -y install ksh.x86_64",
      "sudo yum -y install bind-utils",
      "sudo yum -y install file ncompress",
      "sudo yum -y install ruby-devel.x86_64",
      "sudo yum -y install zlib-devel.x86_64",
      "sudo yum -y install libffi-devel.i686",
      "sudo yum -y install libffi-devel.x86_64",
      "sudo gem install -v 1.8.1 -r winrm",
      "sudo groupadd dba",
      "sudo groupadd oracle",
      "sudo useradd -d /home/oracle -m -s /bin/bash -g oracle oracle",
      "sudo usermod -a -G oracle opc",
      "sudo usermod -a -G dba oracle",
      "sudo groupadd oneworld",
      "sudo useradd -d /home/jde920 -m -s /bin/ksh -g oneworld jde920",
      "sudo usermod -a -G oracle jde920",
      "sudo mkdir ${var.unix_mount_directory}",
      "sudo sed -i 's/.*ClientAliveInterval.*/ClientAliveInterval 3600/' /etc/ssh/sshd_config",
      "sudo sed -i 's/.*AddressFamily inet.*/AddressFamily inet/' /etc/ssh/sshd_config",
      "sudo sed -i 's/Defaults requiretty/#Defaults requiretty/' /etc/ssh/sshd_config",
      "sudo sysctl net.ipv6.conf.default.disable_ipv6=1",
      "sudo sed -i 's/SELINUX.*/SELINUX=disabled/' /etc/selinux/config",
      "sudo sed -i 's/search.*/search jdevcn.oraclevcn.com ${var.pubsubdns}.jdevcn.oraclevcn.com ${var.pvtsubdns}.jdevcn.oraclevcn.com/' /etc/resolv.conf",
      "sudo chattr +i /etc/resolv.conf"

    ]
  }

     provisioner "local-exec" {
         command = "echo \"${self.private_ip} ${self.hostname_label}\" >> ./hosts"
  }

}





