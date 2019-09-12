output "vm_private_key" {
  value = "${tls_private_key.openvas.private_key_pem}"
}

output "vm_ip" {
  value = "${aws_instance.openvas.private_ip}"
}

output "vm_public_ip" {
  value = "${aws_instance.openvas.public_ip}"
}
