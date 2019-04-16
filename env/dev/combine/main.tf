terraform {
  required_version = "< 0.12.0"

  backend "s3" {
    bucket         = "eagle-state"
    key            = "dev/combine/terraform.tfstate"
    encrypt        = true
    kms_key_id     = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
    dynamodb_table = "state_lock"
  }
}

provider "aws" {
  region  = "us-east-1"
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
  vpc_id               = "vpc-01c84ecce478d1efa"
  combine_proxy_eni    = "eni-03b2209b4986c9821"
  availability_zones   = ["us-east-1a", "us-east-1c"]
  dns_suffix           = "pcfeagleci.cf-app.com"
  env_name             = "combine"
  pas_bucket_role_name = "Director"
  kms_key_name         = "pas_kms_key"
  ops_manager_ami      = "ami-0b4e720c1858f1786"
}

module "pas" {
  source                = "../../../terraforming-pas"
  availability_zones    = "${local.availability_zones}"
  dns_suffix            = "${local.dns_suffix}"
  env_name              = "${local.env_name}"
  rds_instance_count    = 0
  pas_bucket_role_name  = "${local.pas_bucket_role_name}"
  use_route53           = false
  use_tcp_routes        = false
  use_ssh_routes        = false
  vpc_id                = "${local.vpc_id}"
  ops_manager_vm        = true
  ops_manager_ami       = "${local.ops_manager_ami}"
  om_eip                = false
  om_eni                = false
  internetless          = true
  kms_key_name          = "${local.kms_key_name}"
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

output "create_db_script_content" {
  value="${module.pas.create_db_script_content}"
}

output "drop_db_script_content" {
  value="${module.pas.drop_db_script_content}"
}

output "ops_manager_infra_vars" {
  value="${module.pas.ops_manager_infra_vars}"
}
