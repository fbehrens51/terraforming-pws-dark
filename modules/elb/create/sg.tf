resource "aws_security_group" "my_elb_sg" {
  name   = "${var.env_name} ${var.short_name} security group"
  vpc_id = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name        = "${var.env_name} ${var.short_name} security group"
      Description = "elb/create module"
    },
  )
}

locals {
  lb_ports = [for i, v in var.listener_to_instance_ports : v.port]
}

resource "aws_security_group_rule" "ingress_rule" {
  count             = length(local.lb_ports)
  description       = "Allow tcp/${local.lb_ports[count.index]} from anywhere"
  from_port         = local.lb_ports[count.index]
  to_port           = local.lb_ports[count.index]
  protocol          = "TCP"
  type              = "ingress"
  security_group_id = aws_security_group.my_elb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_rule" {
  description       = "Allow all protocols/ports to everywhere"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  type              = "egress"
  security_group_id = aws_security_group.my_elb_sg.id
  cidr_blocks       = var.egress_cidrs
}

