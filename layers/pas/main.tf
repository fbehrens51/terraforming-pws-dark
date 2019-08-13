provider "aws" {}

module "providers" {
  source = "../../modules/dark_providers"
}

terraform {
  backend "s3" {}
}

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "paperwork"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

data "terraform_remote_state" "keys" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "keys"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

data "terraform_remote_state" "routes" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "routes"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

data "terraform_remote_state" "bind" {
  backend = "s3"

  config {
    bucket  = "${var.remote_state_bucket}"
    key     = "bind"
    region  = "${var.remote_state_region}"
    encrypt = true
  }
}

module "infra" {
  source = "../../modules/infra"

  env_name               = "${var.env_name}"
  availability_zones     = "${var.availability_zones}"
  internetless           = "${var.internetless}"
  dns_suffix             = ""
  tags                   = "${local.modified_tags}"
  use_route53            = false
  vpc_id                 = "${local.vpc_id}"
  public_route_table_id  = "${local.route_table_id}"
  private_route_table_id = "${data.terraform_remote_state.routes.pas_private_vpc_route_table_id}"
  nat_instance_type      = "${var.nat_instance_type}"
}

module "pas" {
  source             = "../../modules/pas"
  availability_zones = "${var.availability_zones}"
  dns_suffix         = ""
  env_name           = "${var.env_name}"
  public_subnet_ids  = "${module.infra.public_subnet_ids}"
  route_table_id     = "${data.terraform_remote_state.routes.pas_private_vpc_route_table_id}"
  tags               = "${local.modified_tags}"
  vpc_id             = "${local.vpc_id}"
  zone_id            = "${module.infra.zone_id}"
  bucket_suffix      = "${local.bucket_suffix}"
}

module "om_key_pair" {
  source   = "../../modules/key_pair"
  key_name = "${local.om_key_name}"
}

module "rds" {
  source = "../../modules/rds"

  rds_db_username    = "${var.rds_db_username}"
  rds_instance_class = "${var.rds_instance_class}"
  rds_instance_count = "1"

  engine = "mariadb"

  # RDS decided to upgrade the patch version automatically from 10.1.31 to
  # 10.1.34, which makes terraform see this as a change.  Use a prefix version
  # to prevent this from happening.
  engine_version = "10.1"

  db_port = 3306

  env_name           = "${var.env_name}"
  availability_zones = "${var.availability_zones}"
  vpc_id             = "${module.infra.vpc_id}"
  tags               = "${local.modified_tags}"
}

module "pas_elb" {
  source            = "../../modules/elb/create"
  env_name          = "${var.env_name}"
  internetless      = "${var.internetless}"
  public_subnet_ids = "${module.infra.public_subnet_ids}"
  tags              = "${local.modified_tags}"
  vpc_id            = "${local.vpc_id}"
  egress_cidrs      = "${module.pas.pas_subnet_cidrs}"
  short_name        = "pas"
}

module "om_elb" {
  source            = "../../modules/elb/create"
  env_name          = "${var.env_name}"
  internetless      = "${var.internetless}"
  public_subnet_ids = "${module.infra.public_subnet_ids}"
  tags              = "${local.modified_tags}"
  vpc_id            = "${local.vpc_id}"
  egress_cidrs      = "${module.infra.om_subnet_cidrs}"
  short_name        = "om"
}

# Configure the DNS Provider
//TODO support running from CI/Dev wks.  From MJB using the master private IP should work, but that won't work from external CI or our WKS.
provider "dns" {
  update {
    server        = "${local.master_dns_ip}"
    key_name      = "rndc-key."
    key_algorithm = "hmac-md5"
    key_secret    = "${local.bind_rndc_secret}"
  }
}

//update add testing.pivotal-staging.com 600 CNAME dns1.pivotal-staging.com

resource "dns_cname_record" "om_cname" {
  zone  = "${local.dns_zone_name}."
  name  = "om"
  cname = "${module.om_elb.dns_name}."
  ttl   = 300
}

resource "dns_cname_record" "pas_cname" {
  zone  = "${local.dns_zone_name}."
  name  = "*"
  cname = "${module.pas_elb.dns_name}."
  ttl   = 300
}

data "aws_vpc" "cp_vpc" {
  id = "${local.cp_vpc_id}"
}

data "aws_vpc" "pas_vpc" {
  id = "${local.vpc_id}"
}

data "aws_vpc" "bastion_vpc" {
  id = "${local.bastion_vpc_id}"
}

module "ops_manager" {
  source = "../../modules/ops_manager/infra"

  bucket_suffix = "${local.bucket_suffix}"
  env_name      = "${var.env_name}"
  om_eip        = false
  private       = false
  subnet_id     = "${module.infra.om_subnet_ids[0]}"
  tags          = "${local.modified_tags}"
  vpc_id        = "${local.vpc_id}"
  ingress_rules = ["${local.ingress_rules}"]
}

resource "random_integer" "bucket" {
  min = 1
  max = 100000
}

variable "nat_instance_type" {
  default = "t2.small"
}

variable "remote_state_bucket" {}
variable "remote_state_region" {}
variable "rds_db_username" {}
variable "rds_instance_class" {}

variable "env_name" {}

variable "availability_zones" {
  type = "list"
}

variable "internetless" {}

variable "tags" {
  type = "map"
}

locals {
  env_name         = "${var.tags["Name"]}"
  modified_name    = "${local.env_name} pas"
  modified_tags    = "${merge(var.tags, map("Name", "${local.modified_name}"))}"
  cp_vpc_id        = "${data.terraform_remote_state.paperwork.cp_vpc_id}"
  bastion_vpc_id   = "${data.terraform_remote_state.paperwork.bastion_vpc_id}"
  vpc_id           = "${data.terraform_remote_state.paperwork.pas_vpc_id}"
  route_table_id   = "${data.terraform_remote_state.routes.pas_public_vpc_route_table_id}"
  bucket_suffix    = "${random_integer.bucket.result}"
  om_key_name      = "${var.env_name}-om"
  bind_rndc_secret = "${data.terraform_remote_state.keys.bind_rndc_secret}"
  master_dns_ip    = "${data.terraform_remote_state.bind.master_public_ip}"
  dns_zone_name    = "${data.terraform_remote_state.bind.zone_name}"

  ingress_rules = [
    {
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = "${data.aws_vpc.cp_vpc.cidr_block},${data.aws_vpc.bastion_vpc.cidr_block}"
    },
    {
      port        = "443"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

module "calculated_subnets" {
  source   = "../../modules/calculate_subnets"
  vpc_cidr = "${data.aws_vpc.pas_vpc.cidr_block}"
}

output "public_subnet_ids" {
  value = "${module.infra.public_subnet_ids}"
}

output "pas_elb_id" {
  value = "${module.pas_elb.my_elb_id}"
}

output "rds_address" {
  value = "${module.rds.rds_address}"
}

output "rds_password" {
  value     = "${module.rds.rds_password}"
  sensitive = true
}

output "rds_port" {
  value = "${module.rds.rds_port}"
}

output "rds_username" {
  value = "${module.rds.rds_username}"
}

output "pas_buildpacks_bucket" {
  value = "${module.pas.pas_buildpacks_bucket}"
}

output "pas_droplets_bucket" {
  value = "${module.pas.pas_droplets_bucket}"
}

output "pas_packages_bucket" {
  value = "${module.pas.pas_packages_bucket}"
}

output "pas_resources_bucket" {
  value = "${module.pas.pas_resources_bucket}"
}

output "infrastructure_subnet_cidrs" {
  value = "${module.infra.infrastructure_subnet_cidrs}"
}

output "infrastructure_subnet_availability_zones" {
  value = "${module.infra.infrastructure_subnet_availability_zones}"
}

output "infrastructure_subnet_gateways" {
  value = "${module.infra.infrastructure_subnet_gateways}"
}

output "infrastructure_subnet_ids" {
  value = "${module.infra.infrastructure_subnet_ids}"
}

output "pas_subnet_cidrs" {
  value = "${module.pas.pas_subnet_cidrs}"
}

output "pas_subnet_availability_zones" {
  value = "${module.pas.pas_subnet_availability_zones}"
}

output "pas_subnet_gateways" {
  value = "${module.pas.pas_subnet_gateways}"
}

output "pas_subnet_ids" {
  value = "${module.pas.pas_subnet_ids}"
}

output "vms_security_group_id" {
  value = "${module.infra.vms_security_group_id}"
}

output "om_eni_id" {
  value = "${module.ops_manager.om_eni_id}"
}

output "om_elb_id" {
  value = "${module.om_elb.my_elb_id}"
}

output "om_eip_allocation_id" {
  value = "${module.ops_manager.om_eip_allocation_id}"
}

output "om_private_key_pem" {
  value     = "${module.om_key_pair.private_key_pem}"
  sensitive = true
}

output "om_security_group_id" {
  value = "${module.ops_manager.security_group_id}"
}

output "om_ssh_public_key_pair_name" {
  value = "${local.om_key_name}"
}

output "om_dns_name" {
  value = "${dns_cname_record.om_cname.name}.${substr(dns_cname_record.om_cname.zone, 0, length(dns_cname_record.om_cname.zone) - 1)}"
}

output "rds_cidr_block" {
  value = "${module.calculated_subnets.rds_cidr}"
}

output "services_cidr_block" {
  value = "${module.calculated_subnets.services_cidr}"
}

output "om_cidr_block" {
  value = "${module.calculated_subnets.om_cidr}"
}

output "public_cidr_block" {
  value = "${module.calculated_subnets.public_cidr}"
}
