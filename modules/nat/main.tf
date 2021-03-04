variable "internetless" {
}

variable "tags" {
  type = object({ tags = map(string), instance_tags = map(string) })
}

variable "private_route_table_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "instance_type" {
  default = "t3.small"
}

variable "user_data" {
}

variable "bastion_private_ip" {
}

variable "bastion_public_ip" {
}

variable "root_domain" {
}

variable "syslog_ca_cert" {
}

variable "public_bucket_name" {
}

variable "public_bucket_url" {
}

variable "ami_id" {
}

variable "ingress_cidr_blocks" {
  type = list(string)
}

variable "metrics_ingress_cidr_block" {
  type = string
}

variable "bot_key_pem" {
}

variable "check_cloud_init" {
  default = true
}


locals {
  modified_name = "${var.tags.tags["Name"]} nat"
  modified_tags = merge(
    var.tags.tags,
    {
      "Name" = local.modified_name,
    },
  )
  instance_tags = merge(
    local.modified_tags,
    var.tags.instance_tags,
    {
      "job" = "nat"
    }
  )
}

module "eni" {
  source = "../eni_per_subnet"

  ingress_rules = [
    {
      description = "Allow ssh/22 from bastion host"
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = var.bastion_private_ip
    },
    {
      description = "Allow all protocols/ports from ${join(",", var.ingress_cidr_blocks)}"
      port        = "0"
      protocol    = "-1"
      cidr_blocks = join(",", var.ingress_cidr_blocks)
    },
    {
      description = "Allow node_exporter/9100 from pas_vpc"
      port        = "9100"
      protocol    = "tcp"
      cidr_blocks = var.metrics_ingress_cidr_block
    },
  ]

  egress_rules = [
    {
      description = "Allow all protocols/ports to everywhere"
      port        = "0"
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  subnet_ids = var.public_subnet_ids
  eni_count  = length(var.private_route_table_ids)
  tags       = local.modified_tags
  create_eip = ! var.internetless

  source_dest_check = false
}

module "syslog_config" {
  source = "../syslog"

  root_domain        = var.root_domain
  syslog_ca_cert     = var.syslog_ca_cert
  role_name          = replace(local.modified_name, " ", "-")
  public_bucket_name = var.public_bucket_name
  public_bucket_url  = var.public_bucket_url
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
    content      = module.syslog_config.user_data
    content_type = "text/x-include-url"
  }

  part {
    filename     = "other.cfg"
    content_type = "text/cloud-config"
    content      = var.user_data
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }
}

module "nat_host" {
  source = "../launch"

  instance_count   = length(var.private_route_table_ids)
  ami_id           = var.ami_id
  user_data        = data.template_cloudinit_config.user_data.rendered
  eni_ids          = module.eni.eni_ids
  tags             = local.instance_tags
  instance_type    = var.instance_type
  bastion_host     = var.bastion_public_ip
  bot_key_pem      = var.bot_key_pem
  check_cloud_init = var.internetless ? false : var.check_cloud_init
}

resource "aws_route" "toggle_internet" {
  count                  = length(var.private_route_table_ids)
  route_table_id         = var.private_route_table_ids[count.index]
  instance_id            = module.nat_host.instance_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
}

