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

variable "scanner_subnet_id" {
  type    = string
  default = ""
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

locals {

  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} rapid7 scanner"
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
      description = "Allow https to Security Console"
      port        = "3780"
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


module "rapid7_eni" {
  source        = "../../modules/eni_per_subnet"
  create_eip    = !var.internetless
  ingress_rules = local.scanner_ingress_rules
  egress_rules  = local.scanner_egress_rules

  tags = merge(
  var.global_vars["global_tags"],
  {
    "Name" = "${local.env_name} rapid7"
  },
  )
  eni_count    = 1
  subnet_ids   = length(var.scanner_subnet_id) > 1 ? [var.scanner_subnet_id] : [data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_public_subnet_ids[2]]

}

output "eni_ids" {
  value = module.rapid7_eni.eni_ids
}

