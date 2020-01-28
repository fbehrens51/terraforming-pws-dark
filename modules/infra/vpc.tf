data "aws_vpc" "vpc" {
  id = var.vpc_id
}

resource "aws_security_group" "vms_security_group" {
  count = 1

  name        = "vms_security_group"
  description = "VMs Security Group"
  vpc_id      = data.aws_vpc.vpc.id

  tags = merge(
    var.tags,
    {
      "Name" = "${var.env_name}-vms-security-group"
    },
  )
}

resource "aws_security_group_rule" "ingress_from_bastion" {
  security_group_id = aws_security_group.vms_security_group[0].id
  type              = "ingress"
  cidr_blocks       = ["${var.bastion_private_ip}/32"]
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_security_group_rule" "ingress_from_elb" {
  security_group_id        = aws_security_group.vms_security_group[0].id
  type                     = "ingress"
  source_security_group_id = var.elb_security_group_id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
}

resource "aws_security_group_rule" "ingress_from_om" {
  security_group_id        = aws_security_group.vms_security_group[0].id
  type                     = "ingress"
  source_security_group_id = var.ops_manager_security_group_id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
}

// This rule is necessary to allow diego cells in separate isolation segment vpcs to communicate with the PAS control plane + BOSH
resource "aws_security_group_rule" "ingress_from_self" {
  security_group_id = aws_security_group.vms_security_group[0].id
  type              = "ingress"
  self              = true
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
}

resource "aws_security_group_rule" "egress_anywhere" {
  security_group_id = aws_security_group.vms_security_group[0].id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
}
