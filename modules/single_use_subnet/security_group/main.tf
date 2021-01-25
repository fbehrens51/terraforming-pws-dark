variable "vpc_id" {
}

variable "ingress_rules" {
  type = list(object({ description = string, port = string, protocol = string, cidr_blocks = string }))
}

variable "egress_rules" {
  type = list(object({ description = string, port = string, protocol = string, cidr_blocks = string }))
}

variable "tags" {
  type = map(string)
}

resource "aws_security_group" "security_group" {
  vpc_id      = var.vpc_id
  name_prefix = var.tags["Name"]

  tags = merge(
    var.tags,
    {
      Description = "Secrity Group from single_use_subnet"
    }
  )
}

resource "aws_security_group_rule" "egress_rules" {
  count = length(var.egress_rules)

  description = var.egress_rules[count.index]["description"]
  from_port   = var.egress_rules[count.index]["port"]
  to_port     = var.egress_rules[count.index]["port"]

  cidr_blocks = split(",", var.egress_rules[count.index]["cidr_blocks"])

  protocol          = var.egress_rules[count.index]["protocol"]
  security_group_id = aws_security_group.security_group.id
  type              = "egress"
}

resource "aws_security_group_rule" "ingress_rules" {
  count = length(var.ingress_rules)

  description = var.ingress_rules[count.index]["description"]
  from_port   = var.ingress_rules[count.index]["port"]
  to_port     = var.ingress_rules[count.index]["port"]

  cidr_blocks = split(",", var.ingress_rules[count.index]["cidr_blocks"])

  protocol          = var.ingress_rules[count.index]["protocol"]
  security_group_id = aws_security_group.security_group.id
  type              = "ingress"
}

output "security_group_id" {
  value = aws_security_group.security_group.id
}

