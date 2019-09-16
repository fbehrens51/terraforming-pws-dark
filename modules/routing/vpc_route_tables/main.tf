variable "pas_vpc_id" {}
variable "bastion_vpc_id" {}
variable "es_vpc_id" {}
variable "cp_vpc_id" {}
variable "env_name" {}
variable "internetless" {}

module "pas_vpc_route_tables" {
  source       = "../vpc_route_table"
  internetless = "${var.internetless}"
  vpc_id       = "${var.pas_vpc_id}"

  tags = {
    Name = "${var.env_name} | PAS"
  }
}

module "bastion_vpc_route_tables" {
  source       = "../vpc_route_table"
  internetless = "${var.internetless}"
  vpc_id       = "${var.bastion_vpc_id}"

  tags = {
    Name = "${var.env_name} | BASTION"
  }
}

module "es_vpc_route_tables" {
  source       = "../vpc_route_table"
  internetless = "${var.internetless}"
  vpc_id       = "${var.es_vpc_id}"

  tags = {
    Name = "${var.env_name} | ENT SVCS"
  }
}

module "cp_vpc_route_tables" {
  source       = "../vpc_route_table"
  internetless = "${var.internetless}"
  vpc_id       = "${var.cp_vpc_id}"

  tags = {
    Name = "${var.env_name} | CP"
  }
}

output "pas_public_vpc_route_table_id" {
  value = "${module.pas_vpc_route_tables.public_route_table_id}"
}

output "pas_private_vpc_route_table_id" {
  value = "${module.pas_vpc_route_tables.private_route_table_id}"
}

output "bastion_public_vpc_route_table_id" {
  value = "${module.bastion_vpc_route_tables.public_route_table_id}"
}

output "bastion_private_vpc_route_table_id" {
  value = "${module.bastion_vpc_route_tables.private_route_table_id}"
}

output "es_public_vpc_route_table_id" {
  value = "${module.es_vpc_route_tables.public_route_table_id}"
}

output "es_private_vpc_route_table_id" {
  value = "${module.es_vpc_route_tables.private_route_table_id}"
}

output "cp_public_vpc_route_table_id" {
  value = "${module.cp_vpc_route_tables.public_route_table_id}"
}

output "cp_private_vpc_route_table_id" {
  value = "${module.cp_vpc_route_tables.private_route_table_id}"
}
