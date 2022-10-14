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
variable "nat_ssh_cidrs" {
  type = list(string)
}
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
variable "default_instance_role_name" {}
variable "check_cloud_init" {
  type = bool
}
variable "operating_system" {
  type = string
}

variable "global_vars" {
  type = any
}

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

#module "nat" {
#  source                  = "../../../../modules/nat"
#  private_route_table_ids = aws_route_table.private_route_tables.*.id
#
#  ingress_cidr_blocks        = module.isolation_segment_subnets_0.subnet_cidr_blocks
#  metrics_ingress_cidr_block = var.pas_vpc_cidr_block
#  public_subnet_ids          = var.public_subnet_ids
#  tags                       = { tags = local.modified_tags, instance_tags = var.tags.instance_tags }
#  ami_id                     = var.ami_id
#  internetless               = var.internetless
#  ssh_cidr_blocks            = var.nat_ssh_cidrs
#  bot_key_pem                = var.bot_key_pem
#  instance_types             = var.instance_types
#  scale_vpc_key              = "isolation-segment"
#  user_data                  = var.user_data
#  root_domain                = var.root_domain
#  syslog_ca_cert             = var.syslog_ca_cert
#  public_bucket_name         = var.public_bucket_name
#  public_bucket_url          = var.public_bucket_url
#  role_name                  = var.default_instance_role_name
#  check_cloud_init           = var.check_cloud_init
#  iso_seg_name               = var.name
#  operating_system           = var.operating_system
#}

locals {
  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} ${var.name} iso seg"
  ingress_rules = [
    {
      description = "Allow ssh/22 from cp hosts"
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = join(",", var.nat_ssh_cidrs)
    },
    {
      description = "Allow all protocols/ports from ${join(",", module.isolation_segment_subnets_0.subnet_cidr_blocks)}"
      port        = "0"
      protocol    = "-1"
      cidr_blocks = join(",", module.isolation_segment_subnets_0.subnet_cidr_blocks)
    },
    {
      description = "Allow node_exporter/9100 from pas_vpc"
      port        = "9100"
      protocol    = "tcp"
      cidr_blocks = var.pas_vpc_cidr_block
    },
  ]

  egress_rules = [
    {
      description = "Allow all protocols/ports to everywhere"
      port        = "0"
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  tags = merge(
    local.modified_tags,
    {
      "Name" = "${local.modified_name} nat"
    }
  )
}

module "security_group" {
  source         = "../../../../modules/single_use_subnet/security_group"
  ingress_rules  = local.ingress_rules
  egress_rules   = local.egress_rules
  tags           = local.modified_tags
  vpc_id         = var.vpc_id
}

module "nat" {
  source                     = "../../../../modules/nat_v2"
  ami_id                     = var.ami_id
  private_route_table_ids    = aws_route_table.private_route_tables.*.id
  ingress_cidr_blocks        = module.isolation_segment_subnets_0.subnet_cidr_blocks
  metrics_ingress_cidr_block = var.pas_vpc_cidr_block
  tags                       = { tags = local.modified_tags, instance_tags = var.tags.instance_tags }
  public_subnet_ids          = var.public_subnet_ids
  ssh_cidr_blocks            = var.nat_ssh_cidrs
  internetless               = var.internetless
  instance_types             = var.instance_types
  scale_vpc_key              = "isolation-segment"
  user_data                  = var.user_data
  root_domain                = var.root_domain
  syslog_ca_cert             = var.syslog_ca_cert
  bot_key_pem                = var.bot_key_pem
  check_cloud_init           = var.check_cloud_init
  operating_system           = var.operating_system

  public_bucket_name         = var.public_bucket_name
  public_bucket_url          = var.public_bucket_url
  role_name                  = var.default_instance_role_name
  iso_seg_name               = var.name

  security_group_ids = [module.security_group.security_group_id]
}

output "private_route_table_ids" {
  value = aws_route_table.private_route_tables.*.id
}

output "ssh_host_ips" {
  value = module.nat.ssh_host_ips
}
