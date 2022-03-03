locals {
  formatted_env_name      = replace(var.env_name, " ", "-")
  instance_listening_port = var.instance_port == "" ? var.port : var.instance_port
  default_health_check    = "TCP:${local.instance_listening_port}"
}

module "my_elb" {
  source = "../create/elb"
  name   = "${local.formatted_env_name}-${var.short_name}-elb"
  elb_tag = merge(
    var.tags,
    {
      "Name" = "${var.env_name} ${var.short_name} elb"
    },
  )
  health_check      = var.health_check == "" ? local.default_health_check : var.health_check
  elb_sg_id         = aws_security_group.my_elb_sg.id
  internetless      = var.internetless
  public_subnet_ids = var.public_subnet_ids
  port              = var.port
  instance_port     = local.instance_listening_port
  proxy_pass        = var.proxy_pass
}

