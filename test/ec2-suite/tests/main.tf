variable "global_vars" {
  type = any
}

variable "overrides" {
  type = map(map(string))
  default = { }
}


variable "instance_role" {
  type = string
  default = ""
}

variable "region" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}


variable "vpc_id" {
  type = string
}


data "aws_vpc" "this_vpc" {
  id = var.vpc_id
}

locals {
  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} TF validation"
  modified_tags = merge(
    var.global_vars["global_tags"],
    {
      "Name" = local.modified_name
    },
  )
  log_group_name = "${local.env_name}-log-group"
  region         = var.region
  dashboard_name = replace("${local.env_name} Validation", " ", "_")

  defaults = {
    // AL2 VMS
    test-suite = {
      standard   = "t3.medium"
    }
  }
  instance_types = merge(local.defaults, { for product, types in var.overrides : product => merge(local.defaults[product], types) })
  public_cidr_block  = cidrsubnet(data.aws_vpc.this_vpc.cidr_block, 1, 0)
  private_subnets = module.es_private_subnets.subnet_ids_sorted_by_az

  ingress_rules = [
    {
      description = "Allow ssh/22 from everywhere"
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_rules = [
    {
      description = "Allow all protocols/ports to everywhere"
      port        = "-1"
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
}

module "aws_ami" {
  source = "../../../modules/amis/amazon_hvm_ami"
}

module "bootstrap" {
  source        = "../../../modules/eni_per_subnet"
  ingress_rules = local.ingress_rules
  egress_rules  = local.egress_rules
  subnet_ids    = local.private_subnets
  create_eip    = "false"
  eni_count     = "3"
  tags          = local.modified_tags
}

module "es_public_subnets" {
  source      = "../../../modules/get_subnets_by_tag"
  global_vars = var.global_vars
  vpc_id      = data.aws_vpc.this_vpc.id
  subnet_type = "PUBLIC"
}

module "es_private_subnets" {
  source      = "../../../modules/get_subnets_by_tag"
  global_vars = var.global_vars
  vpc_id      = data.aws_vpc.this_vpc.id
  subnet_type = "PRIVATE"
}


module "test_host" {
  instance_count       = 1
  source               = "../../../modules/launch"
  instance_types       = local.instance_types
  scale_vpc_key        = "test-suite"
  scale_service_key    = "standard"
  ami_id               = module.aws_ami.id
  user_data            = ""
  eni_ids              = module.bootstrap.eni_ids
  tags                 = local.modified_tags
  iam_instance_profile = var.instance_role
  operating_system     = "Test-Suite OS"
#  TODO: add instance profile and enable check?
  check_cloud_init = false
}
