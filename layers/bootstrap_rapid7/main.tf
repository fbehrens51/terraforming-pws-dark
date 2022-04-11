variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "region" {
}

variable "global_vars" {
  type = any
}

variable "internetless" {
  type = bool
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

data "terraform_remote_state" "bootstrap_control_plane" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_control_plane"
    region  = var.remote_state_region
    encrypt = true
  }
}


locals {

  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} rapid7 sc"
  formatted_name = replace(local.modified_name, " ", "-")
  rapid7_sc_port = "3780"
  modified_tags = merge(
  var.global_vars["global_tags"],
  var.global_vars["instance_tags"],
  {
    "Name"            = local.modified_name
    "MetricsKey"      = data.terraform_remote_state.paperwork.outputs.metrics_key,
    "foundation_name" = data.terraform_remote_state.paperwork.outputs.foundation_name
    "job"             = "rapid7"
  },
  )

}

resource "aws_lb" "rapid7_sc_lb" {
  name                             = local.formatted_name
  internal                         = false
  load_balancer_type               = "network"
  subnets                          = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_public_subnet_ids
  enable_cross_zone_load_balancing = true
  tags = merge(
    local.modified_tags,
    {
      "Name" = local.modified_name
    },
  )
}

resource "aws_lb_target_group" "rapid7_sc_nlb_https" {
  name_prefix = "r7sc"
  port        = local.rapid7_sc_port
  protocol    = "TCP"
  vpc_id      = data.terraform_remote_state.paperwork.outputs.cp_vpc_id

  tags = {
    Name = "${local.formatted_name}-${local.rapid7_sc_port}"
  }

  lifecycle {
    create_before_destroy = true
  }
#
#  health_check {
#    port = module.syslog_ports.loki_healthcheck_port
#    path = "/ready"
#  }
}

resource "aws_lb_listener" "rapid7_sc_nlb_https" {
  load_balancer_arn = aws_lb.rapid7_sc_lb.arn
  protocol          = "TCP"
  port              = 443

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rapid7_sc_nlb_https.arn
  }
}


locals {
  scanner_egress_rules = [
    {
      description = "Allow all portocols/ports to everywhere"
      port        = "0"
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  scanner_ingress_rules = [
    {
      description = "Allow TCP from Rapid7SC"
      port        = "40814"
      protocol    = "tcp"
      cidr_blocks = join(",", data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_cidrs)
    },
    {
      description = "Allow ssh/22 from cp_vpc"
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = join(",", data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_cidrs)
    },
    {
      // node_exporter metrics endpoint for grafana
      description = "Allow node_exporter/9100 from pas_vpc"
      port        = "9100"
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.pas_vpc.cidr_block
    }
  ]
}

data "aws_vpc" "pas_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
}

module "scanner_eni" {
  source        = "../../modules/eni_per_subnet"
  create_eip    = false
  ingress_rules = local.scanner_ingress_rules
  egress_rules  = local.scanner_egress_rules
  tags = merge(
    var.global_vars["global_tags"],
    {
      "Name" = "${local.env_name} r7-engine"
    },
  )
  eni_count    = 2
  subnet_ids   = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_ids
}

output "scanner_eni_ids" {
  value = module.scanner_eni.eni_ids
}

output "console-tg-id" {
  value = aws_lb_target_group.rapid7_sc_nlb_https.id
}