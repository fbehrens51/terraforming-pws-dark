terraform {
  required_version = "0.11.13"

  backend "s3" {
    bucket = "eagle-state"
    key    = "dev/combine/terraform.tfstate"
    encrypt = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
    dynamodb_table = "combine-state"
  }
}

provider "aws" {
  region     = "${local.region}"
  version = "~> 1.50"
}

provider "random" {
  version = "~> 1.3"
}

provider "template" {
  version = "~> 2.0"
}

provider "tls" {
  version = "~> 1.2"
}

locals {
  vpc_id = "vpc-01c84ecce478d1efa"
  external_om_elb_name = "combine-external-om-lb"
  internal_om_elb_name = "combine-internal-om-lb"
  combine_proxy_eni = "eni-03b2209b4986c9821"
  availability_zones  = ["us-east-1a", "us-east-1c"]
  env_name =  "combine"
  region = "us-east-1"
  ops_manager_ami = "ami-0b4e720c1858f1786"
  pas_bucket_role_name  = "pas_om_bucket_role"
  ops_manager_role_name = "DIRECTOR"
}

module "pas" {
  source                = "../../../terraforming-pas"
  availability_zones    = "${local.availability_zones}"
  dns_suffix            = "pcfeagleci.cf-app.com"
  env_name              = "${local.env_name}"
  rds_instance_count    = 0
  pas_bucket_role_name  = "${local.pas_bucket_role_name}"
  ops_manager_role_name = "${local.ops_manager_role_name}"
  use_route53           = false
  use_tcp_routes        = false
  use_ssh_routes        = false
  vpc_id                = "${local.vpc_id}"
  ops_manager_vm        = true
  ops_manager_ami       = "${local.ops_manager_ami}"
  om_eip                = false
  om_eni                = false
  internetless          = true
  kms_key_name          = "pas_kms_key"
}

//module "ldap" {
//  source = "../tf-modules/ldap-server"
//  env_name = "${local.env_name}"
//  route_table_id = "rtb-0203f0855e9ca250b"
//  internal_ldap_elb_name = "combine-2-internal-ldap-lb"
//  external_ldap_elb_name = "combine-2-external-ldap-lb"
//}

module "portal_cache" {
  source             = "../../../modules/portal-cache"

  vpc_id             = "${local.vpc_id}"
  availability_zones = "${local.availability_zones}"
  env_name           = "${local.env_name}"
}

module "om_config" {
  source = "../../../modules/ops_manager_config"

  redis_host = "${module.portal_cache.redis_host}"
  redis_password = "${module.portal_cache.redis_password}"

  pas_subnet_cidrs = "${module.pas.pas_subnet_cidrs}"
  rds_address = "${module.pas.rds_address}"
  rds_password = "${module.pas.rds_password}"
  rds_port = "${module.pas.rds_port}"
  rds_username = "${module.pas.rds_username}"
  pas_bucket_iam_instance_profile_name = "${module.pas.pas_bucket_iam_instance_profile_name}"
  pas_buildpacks_bucket = "${module.pas.pas_buildpacks_bucket}"
  pas_droplets_bucket = "${module.pas.pas_droplets_bucket}"
  pas_packages_bucket = "${module.pas.pas_packages_bucket}"
  pas_resources_bucket = "${module.pas.pas_resources_bucket}"
  pas_subnet_availability_zones = "${module.pas.pas_subnet_availability_zones}"
  pas_subnet_gateways = "${module.pas.pas_subnet_gateways}"
  pas_subnet_ids = "${module.pas.pas_subnet_ids}"
  vms_security_group_id = "${module.pas.vms_security_group_id}"
  region = "${local.region}"
  ops_manager_ssh_public_key_name = "${module.pas.ops_manager_ssh_public_key_name}"
  ops_manager_ssh_private_key = "${module.pas.ops_manager_ssh_private_key}"
}

# infrastructure, services, and pas all share common route tables
# we only assign the combine proxy route once for all three
data "aws_route_table" "infra_route_tables" {
  count          = "${length(local.availability_zones)}"
  subnet_id      = "${element(module.pas.infrastructure_subnets, count.index)}"
}

resource "aws_route" "route_infrastructure_subnets" {
  count          = "${length(local.availability_zones)}"
  route_table_id = "${element(data.aws_route_table.infra_route_tables.*.id, count.index)}"
  network_interface_id = "${local.combine_proxy_eni}"
  destination_cidr_block = "0.0.0.0/0"
}

# public subnets are already not bound to a route table (since we are not using
# the "gw" module).  We only need to associate those subnets with the same
# route table created above.
resource "aws_route_table_association" "route_public_subnets" {
  count          = "${length(local.availability_zones)}"
  subnet_id      = "${element(module.pas.public_subnets, count.index)}"
  route_table_id = "${element(data.aws_route_table.infra_route_tables.*.id, count.index)}"
}

resource "aws_elb_attachment" "external_om_elb_attachement" {
  elb      = "${local.external_om_elb_name}"
  instance = "${module.pas.ops_manager_instance_id}"
}

resource "aws_elb_attachment" "internal_om_elb_attachement" {
  elb      = "${local.internal_om_elb_name}"
  instance = "${module.pas.ops_manager_instance_id}"
}

output "create_db_script_content" {
  value="${module.om_config.create_db_script_content}"
}

output "drop_db_script_content" {
  value="${module.om_config.drop_db_script_content}"
}

output "ops_manager_infra_vars" {
  value="${module.om_config.ops_manager_infra_vars}"
}