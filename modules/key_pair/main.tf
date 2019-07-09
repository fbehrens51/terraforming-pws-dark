variable "key_name" {}

resource "aws_key_pair" "key_pair" {
  key_name   = "${var.key_name}"
  public_key = "${tls_private_key.private_key.public_key_openssh}"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

output "private_key_pem" {
  value     = "${tls_private_key.private_key.private_key_pem}"
  sensitive = true
}

output "key_name" {
  value = "${aws_key_pair.key_pair.key_name}"
}

output "public_key_openssh" {
  value = "${tls_private_key.private_key.public_key_openssh}"
}
