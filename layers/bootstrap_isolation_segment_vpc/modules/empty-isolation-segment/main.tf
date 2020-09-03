
variable "vpc_id" {}

variable "availability_zones" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}

variable "name" {}
variable "cidr_block" {}
variable "pas_vpc_cidr_block" {}
variable "ami_id" {}
variable "public_subnet_ids" {}
variable "internetless" {}
variable "bastion_private_ip" {}
variable "bastion_public_ip" {}
variable "bot_key_pem" {
  default = null
}
variable "instance_type" {}
variable "user_data" {}
variable "root_domain" {}
variable "syslog_ca_cert" {}
variable "public_bucket_name" {}
variable "public_bucket_url" {}

locals {
  env_name = var.tags["Name"]
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

  tags = local.modified_tags
}

resource "aws_route_table_association" "private_route_table_associations" {
  count          = length(var.availability_zones)
  subnet_id      = module.isolation_segment_subnets_0.subnet_ids[count.index]
  route_table_id = aws_route_table.private_route_tables[count.index].id
}

output "private_route_table_ids" {
  value = aws_route_table.private_route_tables.*.id
}
