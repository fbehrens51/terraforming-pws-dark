
variable "vpc_id" {}

variable "availability_zones" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}

variable "name" {}

variable "cidr_block" {}

locals {
  modified_tags = merge(
    var.tags,
    {
      "isolation_segment" = var.name
    },
  )
}

module "isolation_segment_subnets_0" {
  source = "../../../../modules/subnet_per_az"

  cidr_block         = var.cidr_block
  vpc_id             = var.vpc_id
  availability_zones = var.availability_zones
  tags               = local.modified_tags
}

resource "aws_route_table" "private_route_tables" {
  count  = length(var.availability_zones)
  vpc_id = var.vpc_id

  tags = merge(
    local.modified_tags,
    { "Type" = "PRIVATE" }
  )
}

resource "aws_route_table_association" "private_route_table_associations" {
  count          = length(var.availability_zones)
  subnet_id      = module.isolation_segment_subnets_0.subnet_ids[count.index]
  route_table_id = aws_route_table.private_route_tables[count.index].id
}

output "private_route_table_ids" {
  value = aws_route_table.private_route_tables.*.id
}

output "ssh_host_ips" {
  value = {}
}
