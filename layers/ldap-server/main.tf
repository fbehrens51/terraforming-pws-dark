terraform {
  backend "s3" {
  }
}

provider "aws" {
}

module "providers" {
  source = "../../modules/dark_providers"
}

data "terraform_remote_state" "public-aws-prereqs" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "public-aws-prereqs"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "paperwork"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "bastion" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bastion"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "routes" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "routes"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "enterprise-services" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "enterprise-services"
    region  = var.remote_state_region
    encrypt = true
  }
}

locals {
  env_name      = var.tags["Name"]
  modified_name = "${local.env_name} ldap"
  modified_tags = merge(
    var.tags,
    {
      "Name" = local.modified_name
    },
  )

  root_domain = data.terraform_remote_state.paperwork.outputs.root_domain

  basedn        = "ou=users,dc=${join(",dc=", split(".", local.root_domain))}"
  admin         = "cn=admin,dc=${join(",dc=", split(".", local.root_domain))}"
  public_subnet = data.terraform_remote_state.enterprise-services.outputs.public_subnet_ids[0]

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

module "bootstrap" {
  source        = "../../modules/eni_per_subnet"
  ingress_rules = local.ldap_ingress_rules
  egress_rules  = local.ldap_egress_rules
  subnet_ids    = [local.public_subnet]
  eni_count     = "1"
  create_eip    = "false"
  tags          = local.modified_tags
}

data "aws_eip" "ldap_eip" {
  public_ip = data.terraform_remote_state.paperwork.outputs.ldap_host
}

resource "aws_eip_association" "ldap_eip_association" {
  allocation_id        = data.aws_eip.ldap_eip.id
  network_interface_id = module.bootstrap.eni_ids[0]
}

module "ldap_host" {
  source    = "../../modules/launch"
  ami_id    = module.ubuntu_ami.id
  eni_ids   = module.bootstrap.eni_ids
  user_data = data.terraform_remote_state.paperwork.outputs.bot_user_accounts_user_data

  tags         = local.modified_tags
  bot_key_pem  = data.terraform_remote_state.paperwork.outputs.bot_private_key
  bastion_host = var.internetless ? null : data.terraform_remote_state.bastion.outputs.bastion_ip
}

module "ldap_configure" {
  source = "./modules/ldap-server"

  tls_server_cert = data.terraform_remote_state.public-aws-prereqs.outputs.ldap_server_cert
  tls_server_key  = data.terraform_remote_state.public-aws-prereqs.outputs.ldap_server_key
  user_certs = zipmap(
    data.terraform_remote_state.public-aws-prereqs.outputs.usernames,
    data.terraform_remote_state.public-aws-prereqs.outputs.user_certs,
  )
  tls_server_ca_cert = data.terraform_remote_state.paperwork.outputs.root_ca_cert
  bot_key_pem        = data.terraform_remote_state.paperwork.outputs.bot_private_key
  bastion_host       = var.internetless ? null : data.terraform_remote_state.bastion.outputs.bastion_ip
  instance_id        = module.ldap_host.instance_ids[0]
  private_ip         = module.ldap_host.private_ips[0]
  users              = var.users
  root_domain        = local.root_domain

  basedn   = data.terraform_remote_state.paperwork.outputs.ldap_basedn
  admin    = data.terraform_remote_state.paperwork.outputs.ldap_dn
  password = data.terraform_remote_state.paperwork.outputs.ldap_password
}

module "domains" {
  source = "../../modules/domains"

  root_domain = local.root_domain
}

variable "internetless" {
}

variable "remote_state_region" {
}

variable "remote_state_bucket" {
}

variable "users" {
  type = list(object({ name = string, username = string, roles = string }))
}

variable "tags" {
  type = map(string)
}

output "ldap_private_ip" {
  value = module.bootstrap.eni_ips[0]
}
