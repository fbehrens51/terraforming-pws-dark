locals {
  formatted_env_name   = replace(var.env_name, " ", "-")
  default_health_check = "TCP:${var.port}"
}

module "my_elb" {
  source = "./elb"
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
  additional_port   = var.additional_port
}

