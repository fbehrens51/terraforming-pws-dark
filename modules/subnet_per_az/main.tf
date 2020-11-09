variable "cidr_block" {
}

variable "vpc_id" {
}

variable "availability_zones" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}

locals {
  newbits = ceil(log(length(var.availability_zones), 2))
}

resource "aws_subnet" "subnet" {
  count      = length(var.availability_zones)
  cidr_block = cidrsubnet(var.cidr_block, local.newbits, count.index)
  vpc_id     = var.vpc_id

  availability_zone = var.availability_zones[count.index]

  tags = var.tags
}

output "subnet_ids" {
  value = aws_subnet.subnet.*.id
}

output "subnet_cidr_blocks" {
  value = aws_subnet.subnet.*.cidr_block
}

output "subnet_gateways" {
  value = [
    for cidr in aws_subnet.subnet[*].cidr_block :
    cidrhost(cidr, 1)
  ]
}

