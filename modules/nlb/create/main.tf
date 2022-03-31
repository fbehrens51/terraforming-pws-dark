locals {
  instance_protocol       = "TCP"
  formatted_env_name      = replace(var.env_name, " ", "-")
  instance_listening_port = var.instance_port == null ? var.port : var.instance_port
  health_check_port       = var.health_check_port == null ? local.instance_listening_port : var.health_check_port
}

module "my_nlb" {
  source = "../create/nlb"
  name   = "${local.formatted_env_name}-${var.short_name}-nlb"
  nlb_tag = merge(
    var.tags,
    {
      "Name" = "${var.env_name} ${var.short_name} nlb"
    },
  )
  internetless      = var.internetless
  public_subnet_ids = var.public_subnet_ids
  port              = var.port
  instance_port     = local.instance_listening_port
}

resource "aws_lb_target_group" "my_nlb_tg" {
  name               = "${local.formatted_env_name}-${var.short_name}-nlb-tg"
  port               = var.port
  protocol           = local.instance_protocol
  vpc_id             = var.vpc_id
  preserve_client_ip = var.preserve_client_ip

  health_check {
    port     = local.health_check_port
    protocol = upper(var.health_check_proto)
    path     = var.health_check_path
  }
}

resource "aws_lb_listener" "my_nlb_listener" {
  load_balancer_arn = module.my_nlb.nlb_arn
  protocol          = local.instance_protocol
  port              = var.port

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_nlb_tg.arn
  }
}

resource "aws_security_group" "my_nlb_sg" {
  name   = "${local.formatted_env_name}-${var.short_name}-nlb-sg"
  vpc_id = var.vpc_id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ${var.port} from everywhere to ${local.instance_listening_port}"
    from_port   = var.port
    protocol    = local.instance_protocol
    to_port     = local.instance_listening_port
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all protocols/ports to everywhere"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.formatted_env_name}-${var.short_name}-nlb-sg"
    },
  )
}

resource "aws_security_group" "target_security_group" {
  name   = "${local.formatted_env_name}-${var.short_name}-nlb-sg-vm"
  vpc_id = var.vpc_id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow ${var.port} from everywhere to ${local.instance_listening_port}"
    from_port   = var.port
    protocol    = local.instance_protocol
    to_port     = local.instance_listening_port
  }

  tags = merge(
    var.tags,
    {
      Name = "${local.formatted_env_name}-${var.short_name}-nlb-sg-vm"
    },
  )
}

resource "aws_security_group_rule" "health_check" {
  count             = local.instance_listening_port != local.health_check_port ? 1 : 0
  cidr_blocks       = var.health_check_cidr_blocks
  description       = "Allow ${var.health_check_proto}/${local.health_check_port}"
  from_port         = local.health_check_port
  protocol          = "TCP"
  security_group_id = aws_security_group.my_nlb_sg.id
  to_port           = local.health_check_port
  type              = "ingress"
}

output "nlb_sg_id" {
  value = aws_security_group.my_nlb_sg.id
}

output "nlb_tg_ids" {
  value = [
    aws_lb_target_group.my_nlb_tg.name
  ]
}

output "dns_name" {
  value = module.my_nlb.dns_name
}

output "nlb_name" {
  value = module.my_nlb.nlb_name
}

output "my_nlb_id" {
  value = module.my_nlb.nlb_id
}

output "target_security_group_id" {
  value = aws_security_group.target_security_group.id
}
