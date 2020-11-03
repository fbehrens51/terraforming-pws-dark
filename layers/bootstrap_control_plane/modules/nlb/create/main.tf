variable "short_name" {
  type    = string
  default = "credhub"
}

variable "env_name" {
  type = string
}

variable "internetless" {
  type = bool
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}

variable vpc_id {
}

variable "egress_cidrs" {
  type = list(string)
}

locals {
  formatted_env_name = replace(var.env_name, " ", "-")
}

##########

resource "aws_lb" "concourse_lb" {
  name               = "${local.formatted_env_name}-concourse-lb"
  internal           = var.internetless
  load_balancer_type = "network"
  subnets            = var.public_subnet_ids
  tags = merge(
    var.tags,
    {
      "Name" = "${var.env_name} ${var.short_name} nlb"
    },
  )
}

########## target_groups, 443/2222 on web vm, 8844 on credhub vm

resource "aws_lb_target_group" "concourse_nlb_443" {
  name     = "${local.formatted_env_name}-concourse443"
  port     = 443
  protocol = "TCP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_target_group" "concourse_nlb_2222" {
  name     = "${local.formatted_env_name}-concourse2222"
  port     = 2222
  protocol = "TCP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_target_group" "concourse_nlb_8844" {
  name     = "${local.formatted_env_name}-concourse8844"
  port     = 8844
  protocol = "TCP"
  vpc_id   = var.vpc_id
}

########## listeners

resource "aws_lb_listener" "concourse_nlb_443" {
  load_balancer_arn = aws_lb.concourse_lb.arn
  protocol          = "TCP"
  port              = 443

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.concourse_nlb_443.arn
  }
}

resource "aws_lb_listener" "concourse_nlb_2222" {
  load_balancer_arn = aws_lb.concourse_lb.arn
  protocol          = "TCP"
  port              = 2222

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.concourse_nlb_2222.arn
  }
}

resource "aws_lb_listener" "concourse_nlb_8844" {
  load_balancer_arn = aws_lb.concourse_lb.arn
  protocol          = "TCP"
  port              = 8844

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.concourse_nlb_8844.arn
  }
}

########## Security Group and rules

resource "aws_security_group" "concourse_nlb_security_group" {
  name        = "${local.formatted_env_name}-concourse-nlb-security-group"
  description = "Concourse"
  vpc_id      = var.vpc_id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 2222
    to_port     = 2222
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 8844
    to_port     = 8844
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  tags = merge(
    var.tags,
    {
      "Name" = "${var.env_name}-concourse-nlb-security-group"
    },
  )
}

##########

output "concourse_nlb_security_group_id" {
  value = aws_security_group.concourse_nlb_security_group.id
}

output "credhub_tg_ids" {
  value = [
    aws_lb_target_group.concourse_nlb_8844.name
  ]
}

output "web_tg_ids" {
  value = [
    aws_lb_target_group.concourse_nlb_443.name,
    aws_lb_target_group.concourse_nlb_2222.name
  ]
}

output "concourse_nlb_name" {
  value = aws_lb.concourse_lb.name
}

output "concourse_nlb_dns_name" {
  value = aws_lb.concourse_lb.dns_name
}
