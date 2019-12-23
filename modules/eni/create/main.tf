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
  value = element(concat(aws_network_interface.eni.*.id, [""]), 0)
}

output "private_ip" {
  value = element(concat(aws_network_interface.eni.*.private_ip, [""]), 0)
}

