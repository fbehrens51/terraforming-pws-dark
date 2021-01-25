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

resource "aws_security_group_rule" "ingress_rule" {
  description       = "Allow tcp/${var.port} from anywhere"
  from_port         = var.port
  to_port           = var.port
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

