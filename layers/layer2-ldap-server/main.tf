terraform {
  backend "s3" {}
}

provider "aws" {
  region = "${var.region}"
}

module "providers" {
  source = "../../modules/dark_providers"
}

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "layer0-paperwork"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "terraform_remote_state" "routes" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "layer1-routes"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

locals {
  env_name      = "${var.tags["Name"]}"
  modified_name = "${local.env_name} ldap"
  modified_tags = "${merge(var.tags, map("Name", "${local.modified_name}"))}"
}

module "bootstrap_ldap" {
  source            = "../../modules/single_use_subnet"
  availability_zone = "${var.singleton_availability_zone}"
  route_table_id    = "${data.terraform_remote_state.routes.es_public_vpc_route_table_id}"
  ingress_rules     = "${var.ingress_rules}"
  egress_rules      = "${var.egress_rules}"
  tags              = "${local.modified_tags}"
  create_eip        = true
}

data "aws_region" "current" {}

module "amazon_ami" {
  source = "../../modules/amis/amazon_hvm_ami"
  region = "${data.aws_region.current.name}"
}

module "ubuntu_ami" {
  source = "../../modules/amis/ubuntu_hvm_ami"
  region = "${data.aws_region.current.name}"
}

module "ldap_host_key_pair" {
  source = "../../modules/key_pair"
  name   = "${var.ldap_host_key_pair_name}"
}

module "ldap_host" {
  source        = "../../modules/launch"
  ami_id        = "${module.ubuntu_ami.id}"
  eni_id        = "${module.bootstrap_ldap.eni_id}"
  user_data     = ""
  key_pair_name = "${var.ldap_host_key_pair_name}"
  tags          = "${local.modified_tags}"
}

module "ldap_configure" {
  source = "./modules/ldap-server"

  tls_server_cert     = "${data.terraform_remote_state.paperwork.ldap_server_cert}"
  tls_server_key      = "${data.terraform_remote_state.paperwork.ldap_server_key}"
  ssh_private_key_pem = "${module.ldap_host_key_pair.private_key_pem}"
  ssh_host            = "${module.bootstrap_ldap.public_ips[0]}"
  instance_id         = "${module.ldap_host.instance_id}"
  env_name            = "${local.env_name}"
  users               = "${var.users}"
  domain              = "${var.domain}"
}

module "ldap_elb" {
  source = "../../modules/elb/create"

  env_name          = "${local.env_name}"
  internetless      = false
  public_subnet_ids = ["${module.bootstrap_ldap.public_subnet_id}"]
  tags              = "${var.tags}"
  vpc_id            = "${data.terraform_remote_state.paperwork.es_vpc_id}"
  egress_cidrs      = ["${module.bootstrap_ldap.private_ip}/32"]
  short_name        = "ldap"
  port              = 636
}

resource "aws_elb_attachment" "ldap_attach" {
  elb      = "${module.ldap_elb.my_elb_id}"
  instance = "${module.ldap_host.instance_id}"
}

output "password" {
  value = "${module.ldap_configure.password}"
}

output "ca_cert" {
  value = "${module.ldap_configure.ca_cert}"
}

output "client_cert" {
  value = "${module.ldap_configure.client_cert}"
}

output "client_key" {
  value = "${module.ldap_configure.client_key}"
}

output "dn" {
  value = "${module.ldap_configure.dn}"
}

output "basedn" {
  value = "${module.ldap_configure.basedn}"
}

output "role_attr" {
  value = "${module.ldap_configure.role_attr}"
}

output "host" {
  value = "${module.bootstrap_ldap.public_ips[0]}"
}

output "port" {
  value = "636"
}

variable "domain" {}
variable "remote_state_region" {}
variable "remote_state_bucket" {}
variable "singleton_availability_zone" {}

variable "users" {
  type = "list"
}

variable "ingress_rules" {
  type = "list"
}

variable "egress_rules" {
  type = "list"
}

variable "tags" {
  type = "map"
}

variable "ldap_host_key_pair_name" {}
variable "region" {}
