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

variable "bastion_private_ip" {}

variable "root_domain" {}
variable "splunk_syslog_ca_cert" {}

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

module "nat_ami" {
  source = "../amis/encrypted/amazon2/lookup"
}

module "eni" {
  source = "../eni_per_subnet"

  ingress_rules = [
    {
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = "${var.bastion_private_ip}"
    },
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

module "syslog_config" {
  source = "../syslog"

  root_domain           = "${var.root_domain}"
  splunk_syslog_ca_cert = "${var.splunk_syslog_ca_cert}"
}

data "template_cloudinit_config" "user_data" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "nat.cfg"
    content_type = "text/cloud-config"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"

    content = <<EOF
bootcmd:
  - |
    sysctl -w net.ipv4.ip_forward=1
    /sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
EOF
  }

  part {
    filename     = "syslog.cfg"
    content_type = "text/cloud-config"
    content      = "${module.syslog_config.user_data}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "other.cfg"
    content_type = "text/cloud-config"
    content      = "${var.user_data}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }
}

module "nat_host" {
  source = "../launch"

  instance_count = "1"
  ami_id         = "${module.nat_ami.id}"
  user_data      = "${data.template_cloudinit_config.user_data.rendered}"

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
