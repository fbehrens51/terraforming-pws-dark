data "aws_vpc" "vpc" {
  id = var.vpc_id
}

resource "aws_security_group" "ops_manager_security_group" {
  name        = "ops_manager_security_group"
  description = "Ops Manager Security Group"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all protocols/ports to all hosts"
    cidr_blocks = [var.private ? data.aws_vpc.vpc.cidr_block : "0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.env_name}-ops-manager-security-group"
      Description = "Ops Manager Security Group"
    },
  )
}

resource "aws_security_group_rule" "ingress_rules" {
  count = length(var.ingress_rules)

  description = var.ingress_rules[count.index]["description"]
  from_port   = var.ingress_rules[count.index]["port"]
  to_port     = var.ingress_rules[count.index]["port"]

  cidr_blocks = split(",", var.ingress_rules[count.index]["cidr_blocks"])

  protocol          = var.ingress_rules[count.index]["protocol"]
  security_group_id = aws_security_group.ops_manager_security_group.id
  type              = "ingress"
}

