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

data "terraform_remote_state" "scaling-params" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "scaling-params"
    region  = var.remote_state_region
    encrypt = true
  }
}

locals {
  env_name         = var.global_vars.env_name
  modified_name    = "${local.env_name} rapid7 console"
  modified_tags = merge(
  var.global_vars["global_tags"],
  var.global_vars["instance_tags"],
  {
    "Name"            = local.modified_name
    "MetricsKey"      = data.terraform_remote_state.paperwork.outputs.metrics_key
    "foundation_name" = data.terraform_remote_state.paperwork.outputs.foundation_name
    "job"             = "rapid7_console"
  }
  )
}

data "aws_vpc" "cp_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.cp_vpc_id
}

locals {
  instance_type = data.terraform_remote_state.scaling-params.outputs.instance_types["control-plane"]["r7-console"]
  formatted_name = replace(local.modified_name, " ", "-")
  rapid7_sc_port = "3780"
}
resource "aws_cloudformation_stack" "rapid7_sc" {
  name = "rapid7-security-console"
  //The following is required since the stack creates a custom IAM Role/Instance Profile
  capabilities = ["CAPABILITY_NAMED_IAM"]

  parameters = {
    InstanceType = local.instance_type
    AllowSSHAccessToCIDR = "Yes"
    CIDRToAllowSSH = data.aws_vpc.cp_vpc.cidr_block
    AllowUIAccessToCIDR = "Yes"
    CIDRToAllowUI = "0.0.0.0/0"
    VPC = data.aws_vpc.cp_vpc.id
    Subnet = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_public_subnet_ids[2]
    AssociateConsoleWithPublicIpAddress = "True"
    AccessKeyName = data.terraform_remote_state.paperwork.outputs.bot_key_name
  }

  //URL from AMI (Rapid7 Security console) description or AWS Marketplace
  template_url = "https://s3.amazonaws.com/awsmp-fulfillment-cf-templates-prod/9077b9ec-84f0-40c1-a301-d930d84fdd61.c035342a-4c62-4dda-95c3-cdd229247616.template"
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

