variable "key_name" {
}

resource "aws_key_pair" "key_pair" {
  count = 1

  key_name = var.key_name
  public_key = element(
    tls_private_key.private_key.*.public_key_openssh,
    count.index,
  )
}

resource "tls_private_key" "private_key" {
  count = 1

  algorithm = "RSA"
  rsa_bits  = "4096"
}

output "private_key_pem" {
  value = element(
    concat(tls_private_key.private_key.*.private_key_pem, [""]),
    0,
  )
  sensitive = true
}

output "key_name" {
  value = element(concat(aws_key_pair.key_pair.*.key_name, [""]), 0)
}

output "public_key_openssh" {
  value = element(
    concat(tls_private_key.private_key.*.public_key_openssh, [""]),
    0,
  )
}

