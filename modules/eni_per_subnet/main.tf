variable "ingress_rules" {
  type = list(object({ description = string, port = string, protocol = string, cidr_blocks = string }))
}

variable "egress_rules" {
  type = list(object({ description = string, port = string, protocol = string, cidr_blocks = string }))
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

variable "reserved_ips" {
  type    = list(string)
  default = []
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
  count             = length(var.reserved_ips) > 0 ? 0 : var.eni_count
  subnet_id         = var.subnet_ids[count.index % length(var.subnet_ids)]
  source_dest_check = var.source_dest_check

  security_groups = [
    module.security_group.security_group_id,
  ]

  tags = var.tags
}

resource "aws_network_interface" "eni_with_reserved_ip" {
  count             = length(var.reserved_ips) > 0 ? var.eni_count : 0
  private_ips       = [var.reserved_ips[count.index % length(var.reserved_ips)]]
  subnet_id         = var.subnet_ids[count.index % length(var.subnet_ids)]
  source_dest_check = var.source_dest_check

  security_groups = [
    module.security_group.security_group_id,
  ]

  tags = var.tags
}

resource "aws_eip" "eip" {
  count = var.create_eip ? var.eni_count : 0
  vpc   = true
  tags  = var.tags
}

resource "aws_eip_association" "eip_association" {
  count                = var.create_eip ? var.eni_count : 0
  network_interface_id = length(var.reserved_ips) > 0 ? element(aws_network_interface.eni_with_reserved_ip.*.id, count.index) : element(aws_network_interface.eni.*.id, count.index)
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
  value = length(var.reserved_ips) > 0 ? aws_network_interface.eni_with_reserved_ip.*.id : aws_network_interface.eni.*.id
}

output "eni_ips" {
  value = length(var.reserved_ips) > 0 ? aws_network_interface.eni_with_reserved_ip.*.private_ip : aws_network_interface.eni.*.private_ip
}

