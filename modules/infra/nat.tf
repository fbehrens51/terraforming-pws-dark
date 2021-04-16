module "nat" {
  source                     = "../nat"
  ami_id                     = var.nat_ami_id
  private_route_table_ids    = var.private_route_table_ids
  ingress_cidr_blocks        = [data.aws_vpc.vpc.cidr_block]
  metrics_ingress_cidr_block = data.aws_vpc.vpc.cidr_block
  tags                       = var.tags
  public_subnet_ids          = aws_subnet.public_subnets.*.id
  ssh_cidr_blocks            = var.ssh_cidr_blocks
  internetless               = var.internetless
  instance_types             = var.instance_types
  scale_vpc_key              = "pas"
  user_data                  = var.user_data
  bot_key_pem                = var.bot_key_pem
  check_cloud_init           = var.check_cloud_init

  root_domain    = var.root_domain
  syslog_ca_cert = var.syslog_ca_cert

  public_bucket_name = var.public_bucket_name
  public_bucket_url  = var.public_bucket_url
  role_name          = var.default_instance_role_name
}

