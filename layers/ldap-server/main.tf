terraform {
  backend "s3" {}
}

provider "aws" {}

module "providers" {
  source = "../../modules/dark_providers"
}

data "terraform_remote_state" "public-aws-prereqs" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "public-aws-prereqs"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "paperwork"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "terraform_remote_state" "keys" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "keys"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "terraform_remote_state" "bind" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "bind"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "terraform_remote_state" "routes" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "routes"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

data "terraform_remote_state" "enterprise_services" {
  backend = "s3"

  config {
    bucket     = "${var.remote_state_bucket}"
    key        = "enterprise-services"
    region     = "${var.remote_state_region}"
    encrypt    = true
    kms_key_id = "7a0c75b1-b2e1-490d-8519-0aa44f1ba647"
  }
}

locals {
  env_name      = "${var.tags["Name"]}"
  modified_name = "${local.env_name} ldap"
  modified_tags = "${merge(var.tags, map("Name", "${local.modified_name}"))}"

  bind_rndc_secret = "${data.terraform_remote_state.keys.bind_rndc_secret}"
  master_dns_ip    = "${data.terraform_remote_state.bind.master_public_ip}"
  dns_zone_name    = "${data.terraform_remote_state.bind.zone_name}"

  basedn = "ou=users,dc=${join(",dc=", split(".", var.root_domain))}"
  admin  = "cn=admin,dc=${join(",dc=", split(".", var.root_domain))}"
  public_subnet = "${data.terraform_remote_state.enterprise_services.public_subnet_ids[0]}"

  ldap_ingress_rules = [
    {
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port        = "636"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  ldap_egress_rules = [
    {
      port        = "0"
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

module "ubuntu_ami" {
  source = "../../modules/amis/ubuntu_hvm_ami"
}

module "ldap_host_key_pair" {
  source   = "../../modules/key_pair"
  key_name = "${var.ldap_host_key_pair_name}"
}

module "bootstrap" {
  source = "../../modules/eni_per_subnet"
  ingress_rules = "${local.ldap_ingress_rules}"
  egress_rules = "${local.ldap_egress_rules}"
  subnet_ids = ["${local.public_subnet}"]
  create_eip = "true"
  tags = "${local.modified_tags}"
}

module "ldap_host" {
  source        = "../../modules/launch"
  ami_id        = "${module.ubuntu_ami.id}"
  eni_ids       = "${module.bootstrap.eni_ids}"
  user_data     = ""
  key_pair_name = "${module.ldap_host_key_pair.key_name}"
  tags          = "${local.modified_tags}"
}

module "ldap_configure" {
  source = "./modules/ldap-server"

  tls_server_cert     = "${data.terraform_remote_state.public-aws-prereqs.ldap_server_cert}"
  tls_server_key      = "${data.terraform_remote_state.public-aws-prereqs.ldap_server_key}"
  user_certs          = "${data.terraform_remote_state.public-aws-prereqs.user_certs}"
  tls_server_ca_cert  = "${data.terraform_remote_state.paperwork.root_ca_cert}"
  ssh_private_key_pem = "${module.ldap_host_key_pair.private_key_pem}"
  ssh_host            = "${module.bootstrap.public_ips[0]}"
  instance_id         = "${module.ldap_host.instance_ids[0]}"
  users               = "${var.users}"
  root_domain         = "${var.root_domain}"

  basedn   = "${data.terraform_remote_state.paperwork.ldap_basedn}"
  admin    = "${data.terraform_remote_state.paperwork.ldap_dn}"
  password = "${data.terraform_remote_state.paperwork.ldap_password}"
}

# Configure the DNS Provider
provider "dns" {
  update {
    server        = "${local.master_dns_ip}"
    key_name      = "rndc-key."
    key_algorithm = "hmac-md5"
    key_secret    = "${local.bind_rndc_secret}"
  }
}

resource "dns_a_record_set" "ldap_a_record" {
  zone  = "${local.dns_zone_name}."
  name  = "ldap"
  addresses = ["${module.bootstrap.public_ips}"]
  ttl   = 300
}

variable "root_domain" {}
variable "remote_state_region" {}
variable "remote_state_bucket" {}

variable "users" {
  type = "list"
}

variable "tags" {
  type = "map"
}

variable "ldap_host_key_pair_name" {}

output "ldap_private_ip" {
  value = "${module.bootstrap.eni_ips[0]}"
}
