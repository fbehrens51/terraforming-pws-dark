provider "aws" {
}

module "providers" {
  source = "../../modules/dark_providers"
}

terraform {
  backend "s3" {
  }
}

variable "remote_state_bucket" {
}

variable "remote_state_region" {
}

variable "global_vars" {
  type = any
}

variable "internetless" {
  type = bool
}

variable "scanner_reserved_ip" {
  type    = string
  default = ""
}

variable "scanner_subnet_id" {
  type    = string
  default = ""
}

variable "commercial_scanner" {
  type    = bool
  default = false
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

data "aws_vpc" "pas_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
}

resource "aws_iam_role" "infosec_scanner" {
  count              = var.commercial_scanner == true ? 1 : 0
  name               = "${replace(local.env_name, " ", "-")}-InfosecVulnScanRole"
  assume_role_policy = data.aws_iam_policy_document.role_policy.*.json[0]
}

resource "aws_iam_policy_attachment" "infosec_scanner" {
  count      = var.commercial_scanner == true ? 1 : 0
  name       = "${replace(local.env_name, " ", "-")}-InfosecVulnScanRole"
  roles      = aws_iam_role.infosec_scanner.*.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "infosec_scanner" {
  count = var.commercial_scanner == true ? 1 : 0
  name  = "${replace(local.env_name, " ", "-")}-InfosecVulnScanRole"
  role  = aws_iam_role.infosec_scanner.*.name[0]
}

data "aws_iam_policy_document" "role_policy" {
  count = var.commercial_scanner == true ? 1 : 0
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

locals {

  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} scanner"
  modified_tags = merge(
    var.global_vars["global_tags"],
    var.global_vars["instance_tags"],
    {
      "Name"       = local.modified_name
      "MetricsKey" = data.terraform_remote_state.paperwork.outputs.metrics_key,
      "job"        = "scanner"
    },
  )

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
      description = "Allow https on custom scanner port"
      port        = "8834"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "Allow https"
      port        = "443"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
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

module "scanner_eni" {
  source        = "../../modules/eni_per_subnet"
  create_eip    = ! var.internetless
  ingress_rules = local.scanner_ingress_rules
  egress_rules  = local.scanner_egress_rules
  tags = merge(
    var.global_vars["global_tags"],
    {
      "Name" = "${local.env_name} scanner"
    },
  )
  eni_count    = 1
  subnet_ids   = length(var.scanner_subnet_id) > 1 ? [var.scanner_subnet_id] : [data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_public_subnet_ids[2]]
  reserved_ips = length(var.scanner_reserved_ip) > 0 ? [var.scanner_reserved_ip] : []
}


output "scanner_eni_ids" {
  value = module.scanner_eni.eni_ids
}

output "commercial_scanner_instance_profile_name" {
  value = var.commercial_scanner == true ? aws_iam_instance_profile.infosec_scanner.*.name[0] : "N/A"
}