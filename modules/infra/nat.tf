#module "nat" {
#  source                     = "../nat"
#  ami_id                     = var.nat_ami_id
#  private_route_table_ids    = var.private_route_table_ids
#  ingress_cidr_blocks        = [data.aws_vpc.vpc.cidr_block]
#  metrics_ingress_cidr_block = data.aws_vpc.vpc.cidr_block
#  tags                       = var.tags
#  public_subnet_ids          = aws_subnet.public_subnets.*.id
#  ssh_cidr_blocks            = var.ssh_cidr_blocks
#  internetless               = var.internetless
#  instance_types             = var.instance_types
#  scale_vpc_key              = "pas"
#  user_data                  = var.user_data
#  bot_key_pem                = var.bot_key_pem
#  check_cloud_init           = var.check_cloud_init
#  operating_system           = var.operating_system
#
#  root_domain    = var.root_domain
#  syslog_ca_cert = var.syslog_ca_cert
#
#  public_bucket_name = var.public_bucket_name
#  public_bucket_url  = var.public_bucket_url
#  role_name          = var.default_instance_role_name
#}



locals {

  modified_name = "${var.tags.tags["Name"]} nat"
  modified_tags = merge(
    var.tags.tags,
    {
      "Name" = local.modified_name,
    },
  )
  instance_tags = merge(
    local.modified_tags,
    var.tags.instance_tags,
    {
      "job" = "nat"
    }
  )
  ingress_rules = [
    {
      description = "Allow ssh/22 from cp hosts"
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = join(",", var.ssh_cidr_blocks)
    },
    {
      description = "Allow all protocols/ports from ${join(",", [data.aws_vpc.vpc.cidr_block])}"
      port        = "0"
      protocol    = "-1"
      cidr_blocks = join(",", [data.aws_vpc.vpc.cidr_block])
    },
    {
      description = "Allow node_exporter/9100 from pas_vpc"
      port        = "9100"
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.vpc.cidr_block
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
}

module "security_group" {
  source        = "../../modules/single_use_subnet/security_group"
  ingress_rules = local.ingress_rules
  egress_rules  = local.egress_rules
  tags          = local.modified_tags
  vpc_id        = data.aws_vpc.vpc.id
}

module "nat" {
  source                     = "../nat_v2"
  ami_id                     = var.nat_ami_id
  private_route_table_ids    = var.private_route_table_ids
  ingress_cidr_blocks        = [data.aws_vpc.vpc.cidr_block]
  metrics_ingress_cidr_block = data.aws_vpc.vpc.cidr_block
  tags                       = { tags = local.modified_tags, instance_tags = local.instance_tags }
  public_subnet_ids          = aws_subnet.public_subnets.*.id
  ssh_cidr_blocks            = [data.aws_vpc.vpc.cidr_block]
  internetless               = var.internetless
  instance_types             = var.instance_types
  scale_vpc_key              = "pas"
  user_data                  = var.user_data
  root_domain                = var.root_domain
  syslog_ca_cert             = var.syslog_ca_cert
  bot_key_pem                = var.bot_key_pem
  check_cloud_init           = var.check_cloud_init
  operating_system           = var.operating_system

  public_bucket_name = var.public_bucket_name
  public_bucket_url  = var.public_bucket_url
  role_name          = var.default_instance_role_name

  security_group_ids = [module.security_group.security_group_id]
}