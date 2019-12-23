variable "eni_security_groups" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "eni_subnet_id" {
}

resource "aws_network_interface" "eni" {
  count = 1

  subnet_id = var.eni_subnet_id

  security_groups = var.eni_security_groups

  tags = var.tags
}

output "eni_id" {
  value = aws_network_interface.eni[0].id
}

output "private_ip" {
  value = aws_network_interface.eni[0].private_ip
}

