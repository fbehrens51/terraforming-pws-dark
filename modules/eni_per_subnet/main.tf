variable "ingress_rules" {
  type = list(object({ port = string, protocol = string, cidr_blocks = string }))
}

variable "egress_rules" {
  type = list(object({ port = string, protocol = string, cidr_blocks = string }))
}

variable "subnet_ids" {
  type = list(string)
}

variable "eni_count" {
  description = "The number of enis to create. They will be distributed (round-robin) across the subnets in var.subnet_ids"
}

variable "tags" {
  type = map(string)
}

variable "create_eip" {
}

variable "source_dest_check" {
  default = "true"
}

data "aws_subnet" "first_subnet" {
  id = var.subnet_ids[0]
}

module "security_group" {
  source        = "../single_use_subnet/security_group"
  ingress_rules = var.ingress_rules
  egress_rules  = var.egress_rules
  tags          = var.tags
  vpc_id        = data.aws_subnet.first_subnet.vpc_id
}

resource "aws_network_interface" "eni" {
  count             = var.eni_count
  subnet_id         = var.subnet_ids[count.index % length(var.subnet_ids)]
  source_dest_check = var.source_dest_check

  security_groups = [module.security_group.security_group_id]

  tags = var.tags
}

resource "aws_eip" "eip" {
  count = var.create_eip ? var.eni_count : 0
  vpc   = true
  tags  = var.tags
}

resource "aws_eip_association" "eip_association" {
  count                = var.create_eip ? var.eni_count : 0
  network_interface_id = element(aws_network_interface.eni.*.id, count.index)
  allocation_id        = element(aws_eip.eip.*.id, count.index)
  depends_on           = [aws_eip.eip, aws_network_interface.eni]
}

output "public_ips" {
  value = aws_eip.eip.*.public_ip
}

# output "eip_ids" {
#   value = "${aws_eip.eip.*.id}"
# }

output "eni_ids" {
  value = aws_network_interface.eni.*.id
}

output "eni_ips" {
  value = aws_network_interface.eni.*.private_ip
}

output "security_group_id" {
  value = module.security_group.security_group_id
}

