variable "name" {}

resource "aws_key_pair" "mjb_key_pair" {
  key_name   = "${var.name}"
  public_key = "${tls_private_key.mjb_private_key.public_key_openssh}"
}

resource "tls_private_key" "mjb_private_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

output "private_key_pem" {
  value     = "${tls_private_key.mjb_private_key.private_key_pem}"
  sensitive = true
}
