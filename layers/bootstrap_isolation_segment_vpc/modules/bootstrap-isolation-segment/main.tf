
variable "vpc_id" {}

variable "availability_zones" {
  type = list(string)
}

variable "tags" {
  type = object({ tags = map(string), instance_tags = map(string) })
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
variable "instance_types" {
  type = map(map(string))
}
variable "user_data" {}
variable "root_domain" {}
variable "syslog_ca_cert" {}
variable "public_bucket_name" {}
variable "public_bucket_url" {}

locals {
  modified_tags = merge(
    var.tags.tags,
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

module "nat" {
  source                  = "../../../../modules/nat"
  private_route_table_ids = aws_route_table.private_route_tables.*.id

  ingress_cidr_blocks        = module.isolation_segment_subnets_0.subnet_cidr_blocks
  metrics_ingress_cidr_block = var.pas_vpc_cidr_block
  public_subnet_ids          = var.public_subnet_ids
  tags                       = { tags = local.modified_tags, instance_tags = var.tags.instance_tags }
  ami_id                     = var.ami_id
  internetless               = var.internetless
  bastion_private_ip         = var.bastion_private_ip
  bastion_public_ip          = var.bastion_public_ip
  bot_key_pem                = var.bot_key_pem
  instance_types                  = var.instance_types
  scale_vpc_key = "isolation-segment"
  user_data                  = var.user_data
  root_domain                = var.root_domain
  syslog_ca_cert             = var.syslog_ca_cert
  public_bucket_name         = var.public_bucket_name
  public_bucket_url          = var.public_bucket_url
}

output "private_route_table_ids" {
  value = aws_route_table.private_route_tables.*.id
}
