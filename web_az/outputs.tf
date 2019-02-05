output "webpublicip" {
  value = ["${azure.tf_web.*.public_ip}"]
}

output "webprivateip" {
 value = ["${azure.tf_web.*.private_ip}"]
}

output "webhostname" {
  value = ["${azure.tf_web.*.hostname_label}"] 
  #value = ["${azure.tf_web.*.display_name}"] 
}

