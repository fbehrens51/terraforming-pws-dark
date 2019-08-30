variable "pas_vpc_id" {}
variable "bastion_vpc_id" {}
variable "es_vpc_id" {}
variable "cp_vpc_id" {}
variable "env_name" {}
variable "internetless" {}

resource "aws_route_table" "pas_private_route_table" {
  count = 1

  vpc_id = "${var.pas_vpc_id}"

  tags {
    Name = "${var.env_name} | PAS PRIVATE"
  }
}

resource "aws_route_table" "cp_private_route_table" {
  count = 1

  vpc_id = "${var.cp_vpc_id}"

  tags {
    Name = "${var.env_name} | CP PRIVATE"
  }
}

resource "aws_route_table" "es_private_route_table" {
  count = 1

  vpc_id = "${var.es_vpc_id}"

  tags {
    Name = "${var.env_name} | ENT SVCS PRIVATE"
  }
}

module "pas_public_vpc_route_table" {
  source       = "../vpc_route_table"
  internetless = "${var.internetless}"
  vpc_id       = "${var.pas_vpc_id}"

  tags = {
    Name = "${var.env_name} | PAS PUBLIC"
  }
}

module "bastion_public_vpc_route_table" {
  source       = "../vpc_route_table"
  internetless = "${var.internetless}"
  vpc_id       = "${var.bastion_vpc_id}"

  tags = {
    Name = "${var.env_name} | BASTION PUBLIC"
  }
}

module "es_public_vpc_route_table" {
  source       = "../vpc_route_table"
  internetless = "${var.internetless}"
  vpc_id       = "${var.es_vpc_id}"

  tags = {
    Name = "${var.env_name} | ENT SVCS PUBLIC"
  }
}

module "cp_public_vpc_route_table" {
  source       = "../vpc_route_table"
  internetless = "${var.internetless}"
  vpc_id       = "${var.cp_vpc_id}"

  tags = {
    Name = "${var.env_name} | CP PUBLIC"
  }
}

output "pas_private_vpc_route_table_id" {
  value = "${element(concat(aws_route_table.pas_private_route_table.*.id, list("")), 0)}"
}

output "pas_public_vpc_route_table_id" {
  value = "${module.pas_public_vpc_route_table.route_table_id}"
}

output "bastion_public_vpc_route_table_id" {
  value = "${module.bastion_public_vpc_route_table.route_table_id}"
}

output "es_private_vpc_route_table_id" {
  value = "${element(concat(aws_route_table.es_private_route_table.*.id, list("")), 0)}"
}

output "es_public_vpc_route_table_id" {
  value = "${module.es_public_vpc_route_table.route_table_id}"
}

output "cp_private_vpc_route_table_id" {
  value = "${element(concat(aws_route_table.cp_private_route_table.*.id, list("")), 0)}"
}

output "cp_public_vpc_route_table_id" {
  value = "${module.cp_public_vpc_route_table.route_table_id}"
}
