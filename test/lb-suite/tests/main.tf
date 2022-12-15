variable "global_vars" {
  type = any
}

variable "overrides" {
  type    = map(map(string))
  default = {}
}


variable "instance_role" {
  type    = string
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


variable "internetless" {
  type    = bool
  default = true
}

variable "elb_idle_timeout" {
  type        = number
  default     = 600
  description = "idle timeout in seconds for the elb"
}

variable "instance_type" {
  type    = string
  default = "t2.small"
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


  listener_to_instance_ports = [{
    port                = 443
    instance_port       = 443
    enable_proxy_policy = true
  }]


  private_subnets = module.es_private_subnets.subnet_ids_sorted_by_az
  public_subnets  = module.es_public_subnets.subnet_ids_sorted_by_az
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


#aws_elb
#aws_proxy_protocol_policy
module "test_elb" {
  source            = "../../../modules/elb/create"
  env_name          = var.global_vars.name_prefix
  internetless      = var.internetless
  public_subnet_ids = local.public_subnets
  tags              = local.modified_tags
  vpc_id            = var.vpc_id
  egress_cidrs      = [data.aws_vpc.this_vpc.cidr_block]
  short_name        = "test"
  health_check      = "HTTP:8080/health"

  proxy_pass                 = true
  idle_timeout               = var.elb_idle_timeout
  listener_to_instance_ports = local.listener_to_instance_ports
}

#"aws_lb"
#"aws_lb_listener"
#"aws_lb_target_group"
module "test_nlb" {
  source                   = "../../../modules/nlb/create"
  env_name                 = var.global_vars.name_prefix
  internetless             = var.internetless
  public_subnet_ids        = local.public_subnets
  tags                     = local.modified_tags
  vpc_id                   = var.vpc_id
  egress_cidrs             = [data.aws_vpc.this_vpc.cidr_block]
  short_name               = "test"
  port                     = 443
  health_check_path        = "/api/health"
  health_check_port        = 443
  health_check_proto       = "HTTPS"
  health_check_cidr_blocks = data.aws_vpc.this_vpc.cidr_block
}

module "aws_ami" {
  source = "../../../modules/amis/amazon_hvm_ami"
}

resource "aws_instance" "test_instance" {
  count         = length(local.private_subnets)
  ami           = module.aws_ami.id
  subnet_id     = local.private_subnets[count.index]
  instance_type = var.instance_type
}

resource "aws_lb_target_group_attachment" "test_attachment" {
  count            = length(local.private_subnets)
  target_group_arn = module.test_nlb.target_group_arn
  target_id        = aws_instance.test_instance[count.index].id
}

