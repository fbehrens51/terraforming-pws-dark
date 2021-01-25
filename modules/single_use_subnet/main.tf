variable "route_table_id" {
}

variable "availability_zone" {
  description = "AZ, specify or will default to first in list of available"
  default     = ""
}

variable "ingress_rules" {
  type = list(object({ description = string, port = string, protocol = string, cidr_blocks = string }))
}

variable "egress_rules" {
  type = list(object({ description = string, port = string, protocol = string, cidr_blocks = string }))
}

variable "tags" {
  type = map(string)
}

variable "create_eip" {
}

variable "cidr_block" {
}

data "aws_route_table" "route_table" {
  route_table_id = var.route_table_id
}

data "aws_vpc" "vpc" {
  id = data.aws_route_table.route_table.vpc_id
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  availability_zone = var.availability_zone != "" ? var.availability_zone : data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "public_subnet" {
  count = 1

  cidr_block        = var.cidr_block
  vpc_id            = data.aws_vpc.vpc.id
  availability_zone = local.availability_zone

  tags = var.tags
}

module "security_groups" {
  source        = "./security_group"
  ingress_rules = var.ingress_rules
  egress_rules  = var.egress_rules
  tags          = var.tags
  vpc_id        = aws_subnet.public_subnet[0].vpc_id
}

module "eni" {
  source              = "../eni/create"
  eni_security_groups = [module.security_groups.security_group_id]
  eni_subnet_id       = aws_subnet.public_subnet[0].id
  tags                = var.tags
}

resource "aws_eip" "eip" {
  count = var.create_eip ? 1 : 0
  vpc   = true
}

resource "aws_eip_association" "eip_association" {
  count                = var.create_eip ? 1 : 0
  allocation_id        = aws_eip.eip[0].id
  network_interface_id = module.eni.eni_id
}

resource "aws_route_table_association" "route_public_subnet" {
  subnet_id      = aws_subnet.public_subnet[0].id
  route_table_id = var.route_table_id
}

output "public_subnet_id" {
  value = aws_subnet.public_subnet[0].id
}

output "eni_id" {
  value = module.eni.eni_id
}

output "public_ips" {
  value = aws_eip.eip.*.public_ip
}

output "private_ip" {
  value = module.eni.private_ip
}

output "cidr_block" {
  value = aws_subnet.public_subnet[0].cidr_block
}

