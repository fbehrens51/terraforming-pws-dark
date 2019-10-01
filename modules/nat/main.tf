variable "internetless" {}

variable "tags" {
  type = "map"
}

variable "private_route_table_id" {}

variable "public_subnet_id" {}

variable "instance_type" {
  default = "t2.small"
}

variable "ssh_banner" {}

variable "user_data" {}

locals {
  env_name      = "${var.tags["Name"]}"
  modified_name = "${local.env_name} nat"
  modified_tags = "${merge(var.tags, map("Name", "${local.modified_name}"))}"
}

data "aws_route_table" "private_route_table" {
  route_table_id = "${var.private_route_table_id}"
}

data "aws_vpc" "vpc" {
  id = "${data.aws_route_table.private_route_table.vpc_id}"
}

data "aws_ami" "nat_ami" {
  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat*"]
  }

  most_recent = true
  owners      = ["amazon"]
}

module "eni" {
  source = "../eni_per_subnet"

  ingress_rules = [
    {
      port        = "0"
      protocol    = "-1"
      cidr_blocks = "${data.aws_vpc.vpc.cidr_block}"
    },
  ]

  egress_rules = [
    {
      port        = "0"
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  subnet_ids = ["${var.public_subnet_id}"]
  eni_count  = 1
  tags       = "${local.modified_tags}"
  create_eip = "${!var.internetless}"

  source_dest_check = false
}

module "nat_host" {
  source = "../launch"

  instance_count = "1"
  ami_id         = "${data.aws_ami.nat_ami.image_id}"
  user_data      = "${var.user_data}"

  ssh_banner = "${var.ssh_banner}"
  eni_ids    = ["${module.eni.eni_ids[0]}"]

  tags          = "${local.modified_tags}"
  instance_type = "${var.instance_type}"
}

resource "aws_route" "toggle_internet" {
  route_table_id         = "${var.private_route_table_id}"
  instance_id            = "${module.nat_host.instance_ids[0]}"
  destination_cidr_block = "0.0.0.0/0"
}
