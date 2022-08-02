data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "paperwork"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "scaling-params" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "scaling-params"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_control_plane" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_control_plane"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "template_cloudinit_config" "nat_user_data" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "tag_completion.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.completion_tag_user_data
  }

  part {
    filename     = "clamav.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.amazon2_clamav_user_data
  }

  part {
    filename     = "node_exporter.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.node_exporter_user_data
  }

  part {
    filename     = "banner.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.custom_banner_user_data
  }

  part {
    filename     = "bot_user_accounts_user_data.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.bot_user_accounts_user_data
  }

  part {
    filename     = "iptables.cfg"
    content_type = "text/cloud-config"
    content      = module.iptables_rules.iptables_user_data
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "postfix_client.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.postfix_client_user_data
  }

  # This must be last - updates the AIDE DB after all installations/configurations are complete.
  part {
    filename     = "hardening.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.server_hardening_user_data
  }
}

data "aws_route_table" "pas_public_route_table" {
  vpc_id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
  tags   = merge(var.global_vars["global_tags"], { "Type" = "PUBLIC" })
}


data "aws_route_tables" "pas_private_route_tables" {
  vpc_id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
  tags   = merge(var.global_vars["global_tags"], { "Type" = "PRIVATE" })
}

module "iptables_rules" {
  source                     = "../../modules/iptables"
  nat                        = true
  control_plane_subnet_cidrs = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_cidrs
}

module "infra" {
  source = "../../modules/infra"

  nat_ami_id = data.terraform_remote_state.paperwork.outputs.amzn_ami_id

  env_name                      = var.global_vars.name_prefix
  availability_zones            = var.availability_zones
  internetless                  = var.internetless
  dns_suffix                    = ""
  tags                          = { tags = local.modified_tags, instance_tags = var.global_vars["instance_tags"] }
  use_route53                   = false
  vpc_id                        = local.vpc_id
  public_route_table_id         = local.route_table_id
  ssh_cidr_blocks               = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_cidrs
  bot_key_pem                   = data.terraform_remote_state.paperwork.outputs.bot_private_key
  private_route_table_ids       = data.aws_route_tables.pas_private_route_tables.ids
  root_domain                   = data.terraform_remote_state.paperwork.outputs.root_domain
  instance_types                = data.terraform_remote_state.scaling-params.outputs.instance_types
  syslog_ca_cert                = data.terraform_remote_state.paperwork.outputs.syslog_ca_certs_bundle
  ops_manager_security_group_id = module.ops_manager.security_group_id
  elb_security_group_id         = module.pas_elb.security_group_id
  grafana_elb_security_group_id = module.grafana_elb.security_group_id
  operating_system              = data.terraform_remote_state.paperwork.outputs.amazon_operating_system_tag

  user_data = data.template_cloudinit_config.nat_user_data.rendered

  check_cloud_init = data.terraform_remote_state.paperwork.outputs.check_cloud_init == "false" ? false : true

  public_bucket_name         = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url          = data.terraform_remote_state.paperwork.outputs.public_bucket_url
  default_instance_role_name = data.terraform_remote_state.paperwork.outputs.instance_tagger_role_name
}

module "om_key_pair" {
  source   = "../../modules/key_pair"
  key_name = local.om_key_name
}

module "pas" {
  source                       = "../../modules/pas"
  availability_zones           = var.availability_zones
  dns_suffix                   = ""
  env_name                     = var.global_vars.name_prefix
  public_subnet_ids            = module.infra.public_subnet_ids
  route_table_ids              = data.aws_route_tables.pas_private_route_tables.ids
  tags                         = local.modified_tags
  vpc_id                       = local.vpc_id
  zone_id                      = module.infra.zone_id
  bucket_suffix                = local.bucket_suffix
  create_backup_pas_buckets    = false
  create_versioned_pas_buckets = true
  s3_logs_bucket               = data.terraform_remote_state.paperwork.outputs.s3_logs_bucket
}


module "tag_vpc" {
  source   = "../../modules/vpc_tagging"
  vpc_id   = local.vpc_id
  name     = "pas"
  purpose  = "pas"
  env_name = local.env_name
}


module "postgres" {
  source = "../../modules/rds/instance"

  rds_db_username    = "superuser"
  rds_instance_class = var.rds_instance_class

  engine = "postgres"

  # RDS decided to upgrade the mysql patch version automatically from 10.1.31 to
  # 10.1.34, which makes terraform see this as a change. Use a prefix version to
  # prevent this from happening with postgres.
  engine_version = var.pas_postgres_engine_version

  db_port      = 5432
  sg_rule_desc = "postgres/5432"

  env_name = local.modified_name
  vpc_id   = module.infra.vpc_id
  tags     = local.modified_tags

  subnet_group_name = module.rds_subnet_group.subnet_group_name

  kms_key_id = data.terraform_remote_state.paperwork.outputs.kms_key_arn

  database_deletion_protection = var.database_deletion_protection
}

module "rds" {
  source = "../../modules/rds/instance"

  rds_db_username    = var.rds_db_username
  rds_instance_class = var.rds_instance_class

  engine = var.pas_db_engine

  # RDS decided to upgrade the patch version automatically from 10.1.31 to
  # 10.1.34, which makes terraform see this as a change.  Use a prefix version
  # to prevent this from happening.
  engine_version = var.pas_db_engine_version

  db_port      = 3306
  sg_rule_desc = "rds/3306"

  env_name = var.global_vars.name_prefix
  vpc_id   = module.infra.vpc_id
  tags     = local.modified_tags

  subnet_group_name = module.rds_subnet_group.subnet_group_name

  kms_key_id = data.terraform_remote_state.paperwork.outputs.kms_key_arn

  database_deletion_protection = var.database_deletion_protection
}

module "rds_subnet_group" {
  source = "../../modules/rds/subnet_group"

  env_name           = var.global_vars.name_prefix
  availability_zones = var.availability_zones
  vpc_id             = module.infra.vpc_id
  cidr_block         = module.calculated_subnets.rds_cidr
  tags               = local.modified_tags
}

module "grafana_nlb" {
  source                   = "../../modules/nlb/create"
  env_name                 = var.global_vars.name_prefix
  internetless             = var.internetless
  public_subnet_ids        = module.infra.public_subnet_ids
  tags                     = local.modified_tags
  vpc_id                   = local.vpc_id
  egress_cidrs             = module.pas.pas_subnet_cidrs
  short_name               = "grafana"
  port                     = 443
  health_check_path        = "/api/health"
  health_check_port        = 443
  health_check_proto       = "HTTPS"
  health_check_cidr_blocks = module.infra.public_subnet_cidrs
}

module "grafana_elb" {
  source            = "../../modules/elb/create"
  env_name          = var.global_vars.name_prefix
  internetless      = var.internetless
  public_subnet_ids = module.infra.public_subnet_ids
  tags              = local.modified_tags
  vpc_id            = local.vpc_id
  egress_cidrs      = module.pas.pas_subnet_cidrs
  short_name        = "grafana"
  port              = 443
  health_check      = "HTTPS:443/api/health"
}

module "pas_elb" {
  source            = "../../modules/elb/create"
  env_name          = var.global_vars.name_prefix
  internetless      = var.internetless
  public_subnet_ids = module.infra.public_subnet_ids
  tags              = local.modified_tags
  vpc_id            = local.vpc_id
  egress_cidrs      = module.pas.pas_subnet_cidrs
  short_name        = "pas"
  health_check      = "HTTP:8080/health" # Gorouter healthcheck
  proxy_pass        = true
  idle_timeout      = var.pas_elb_idle_timeout
}

data "aws_vpc" "cp_vpc" {
  id = local.cp_vpc_id
}

data "aws_vpc" "pas_vpc" {
  id = local.vpc_id
}

module "ops_manager" {
  source = "../../modules/ops_manager/infra"

  bucket_suffix_name    = local.bucket_suffix_name
  env_name              = var.global_vars.name_prefix
  om_eip                = !var.internetless
  private               = false
  subnet_id             = module.infra.public_subnet_ids[0]
  tags                  = local.modified_tags
  vpc_id                = local.vpc_id
  ingress_rules         = local.ingress_rules
  s3_logs_bucket        = local.s3_logs_bucket
  force_destroy_buckets = var.force_destroy_buckets
  operating_system      = data.terraform_remote_state.paperwork.outputs.amazon_operating_system_tag
}

resource "random_integer" "bucket" {
  min = 1
  max = 100000
}

variable "pas_db_engine" {
  default = "mysql"
}

variable "pas_db_engine_version" {
  default = "5.7"
}

variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "rds_db_username" {
}

variable "rds_instance_class" {
}

variable "availability_zones" {
  type = list(string)
}

variable "internetless" {
}

variable "global_vars" {
  type = any
}

variable "pas_grafana_nlb" {
  type        = bool
  default     = false
  description = "false = use elb, true = use nlb"
}

variable "pas_elb_idle_timeout" {
  type = number
  default = 600
  description = "idle timeout in seconds for the pas elb"
}

locals {

  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} pas"
  modified_tags = merge(
    var.global_vars["global_tags"],
    {
      "Name"            = local.modified_name
      "MetricsKey"      = data.terraform_remote_state.paperwork.outputs.metrics_key,
      "foundation_name" = data.terraform_remote_state.paperwork.outputs.foundation_name
    },
  )

  secrets_bucket_name = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  cp_vpc_id           = data.terraform_remote_state.paperwork.outputs.cp_vpc_id
  vpc_id              = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
  route_table_id      = data.aws_route_table.pas_public_route_table.id
  bucket_suffix       = random_integer.bucket.result
  bucket_suffix_name  = "pas"
  root_domain         = data.terraform_remote_state.paperwork.outputs.root_domain
  om_key_name         = "${var.global_vars.name_prefix}-om"
  s3_logs_bucket      = data.terraform_remote_state.paperwork.outputs.s3_logs_bucket

  ingress_rules = [
    {
      description = "Allow ssh/22 from cp_vpc"
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.cp_vpc.cidr_block
    },
    {
      description = "Allow https/443 from everywhere"
      port        = "443"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "Allow node_exporter/9100 from pas_vpc"
      port        = "9100"
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.pas_vpc.cidr_block
    },
  ]
}

module "calculated_subnets" {
  source   = "../../modules/calculate_subnets"
  vpc_cidr = data.aws_vpc.pas_vpc.cidr_block
}

output "ssh_host_ips" {
  value = module.infra.ssh_host_ips
}

output "om_private_key_pem" {
  value     = module.om_key_pair.private_key_pem
  sensitive = true
}

output "public_subnet_ids" {
  value = module.infra.public_subnet_ids
}

output "pas_elb_dns_name" {
  value = module.pas_elb.dns_name
}

output "pas_elb_id" {
  value = module.pas_elb.my_elb_id
}

output "grafana_elb_dns_name" {
  value = var.pas_grafana_nlb == true ? module.grafana_nlb.dns_name : module.grafana_elb.dns_name
}

output "grafana_elb_id" {
  value = module.grafana_elb.my_elb_id
}

output "grafana_tg_names" {
  value = module.grafana_nlb.nlb_tg_ids
}

output "grafana_nlb_id" {
  value = module.grafana_nlb.my_nlb_id
}

output "grafana_lb_security_group_id" {
  value = [
    module.grafana_nlb.target_security_group_id,
    module.infra.vms_security_group_id
  ]
}

output "postgres_rds_address" {
  value = module.postgres.rds_address
}

output "postgres_rds_port" {
  value = module.postgres.rds_port
}

output "postgres_rds_username" {
  value = module.postgres.rds_username
}

output "postgres_rds_password" {
  value     = module.postgres.rds_password
  sensitive = true
}

output "rds_address" {
  value = module.rds.rds_address
}

output "rds_password" {
  value     = module.rds.rds_password
  sensitive = true
}

output "rds_port" {
  value = module.rds.rds_port
}

output "rds_username" {
  value = module.rds.rds_username
}

output "rds_subnet_group_name" {
  value = module.rds_subnet_group.subnet_group_name
}

output "ops_manager_bucket" {
  value = module.ops_manager.bucket
}

output "director_blobstore_bucket" {
  value = module.ops_manager.director_blobstore_bucket
}

output "pas_buildpacks_bucket" {
  value = module.pas.pas_buildpacks_bucket
}

output "pas_droplets_bucket" {
  value = module.pas.pas_droplets_bucket
}

output "pas_packages_bucket" {
  value = module.pas.pas_packages_bucket
}

output "pas_resources_bucket" {
  value = module.pas.pas_resources_bucket
}

output "pas_buildpacks_backup_bucket" {
  value = module.pas.pas_buildpacks_backup_bucket
}

output "pas_droplets_backup_bucket" {
  value = module.pas.pas_droplets_backup_bucket
}

output "pas_packages_backup_bucket" {
  value = module.pas.pas_packages_backup_bucket
}

output "pas_resources_backup_bucket" {
  value = module.pas.pas_resources_backup_bucket
}

output "infrastructure_subnet_cidrs" {
  value = module.infra.infrastructure_subnet_cidrs
}

output "infrastructure_subnet_availability_zones" {
  value = module.infra.infrastructure_subnet_availability_zones
}

output "infrastructure_subnet_gateways" {
  value = module.infra.infrastructure_subnet_gateways
}

output "infrastructure_subnet_ids" {
  value = module.infra.infrastructure_subnet_ids
}

output "pas_subnet_cidrs" {
  value = module.pas.pas_subnet_cidrs
}

output "pas_subnet_availability_zones" {
  value = module.pas.pas_subnet_availability_zones
}

output "pas_subnet_gateways" {
  value = module.pas.pas_subnet_gateways
}

output "pas_subnet_ids" {
  value = module.pas.pas_subnet_ids
}

output "vms_security_group_id" {
  value = module.infra.vms_security_group_id
}

output "om_eni_id" {
  value = module.ops_manager.om_eni_id
}

output "om_bucket_arn" {
  value = module.ops_manager.bucket_arn
}

output "director_blobstore_bucket_arn" {
  value = module.ops_manager.director_blobstore_bucket_arn
}

output "om_eip_allocation" {
  value = module.ops_manager.om_eip_allocation
}

output "om_security_group_id" {
  value = module.ops_manager.security_group_id
}

output "rds_cidr_block" {
  value = module.calculated_subnets.rds_cidr
}

output "services_cidr_block" {
  value = module.calculated_subnets.services_cidr
}

output "public_cidr_block" {
  value = module.calculated_subnets.public_cidr
}

output "ops_manager_ip" {
  value = module.ops_manager.ip
}

variable "force_destroy_buckets" {
  type    = bool
  default = false
}

variable "database_deletion_protection" {
  type    = bool
  default = true
}

locals {
  default_vpcs = [
    data.terraform_remote_state.paperwork.outputs.pas_vpc_id,
    data.terraform_remote_state.paperwork.outputs.bastion_vpc_id,
    data.terraform_remote_state.paperwork.outputs.cp_vpc_id,
    data.terraform_remote_state.paperwork.outputs.es_vpc_id,
  ]
}

data "aws_vpc" "default_vpcs" {
  count = length(local.default_vpcs)
  id    = local.default_vpcs[count.index]
}

resource "aws_s3_bucket_object" "blocked-vpc" {
  count        = length(local.default_vpcs)
  bucket       = local.secrets_bucket_name
  content_type = "text/plain"
  key          = "blocked-cidrs/platform-${local.default_vpcs[count.index]}"
  content      = data.aws_vpc.default_vpcs[count.index].cidr_block
}

resource "aws_s3_bucket_object" "allowed-cidr" {
  bucket       = local.secrets_bucket_name
  content_type = "application/json"
  key          = "allowed-cidrs/platform-public-cidr"
  content      = jsonencode({ "description" : "Allow access to foundation public subnet", "destination" : module.calculated_subnets.public_cidr, "protocol" : "all" })
}

resource "aws_s3_bucket_object" "rds-password" {
  bucket       = local.secrets_bucket_name
  content_type = "text/plain"
  key          = "pas/rds-password"
  content      = module.rds.rds_password
}

resource "aws_s3_bucket_object" "postgres-rds-password" {
  bucket       = local.secrets_bucket_name
  content_type = "text/plain"
  key          = "pas/postgres-rds-password"
  content      = module.postgres.rds_password
}

variable "pas_postgres_engine_version" {
  default     = "9.6"
  description = "version prefix for posgtres rds instance available in pas VPC"
}


module "sshconfig" {
  source         = "../../modules/ssh_config"
  foundation_name = data.terraform_remote_state.paperwork.outputs.foundation_name
  host_ips = module.infra.ssh_host_ips
  host_type = "pas_nat"
  secrets_bucket_name = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
}