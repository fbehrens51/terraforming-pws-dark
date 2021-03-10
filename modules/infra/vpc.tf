data "aws_vpc" "vpc" {
  id = var.vpc_id
}

resource "aws_security_group" "vms_security_group" {
  count = 1

  name        = "vms_security_group"
  description = "VMs Security Group"
  vpc_id      = data.aws_vpc.vpc.id

  tags = merge(
    var.tags.tags,
    {
      Name        = "${var.env_name}-vms-security-group"
      Description = "infra/vpc module"
    },
  )
}

resource "aws_security_group_rule" "ingress_from_bastion_cp" {
  description       = "Allow ssh/22 from bastion host"
  security_group_id = aws_security_group.vms_security_group[0].id
  type              = "ingress"
  cidr_blocks       = var.ssh_cidr_blocks
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_security_group_rule" "ingress_from_elb" {
  description              = "Allow all protocols/ports from the ELB"
  security_group_id        = aws_security_group.vms_security_group[0].id
  type                     = "ingress"
  source_security_group_id = var.elb_security_group_id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
}

resource "aws_security_group_rule" "ingress_from_grafana_elb" {
  description              = "Allow all protocols/ports from the grafana ELB"
  security_group_id        = aws_security_group.vms_security_group[0].id
  type                     = "ingress"
  source_security_group_id = var.grafana_elb_security_group_id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
}

resource "aws_security_group_rule" "ingress_from_om" {
  description              = "Allow all protocols/ports from OM"
  security_group_id        = aws_security_group.vms_security_group[0].id
  type                     = "ingress"
  source_security_group_id = var.ops_manager_security_group_id
  protocol                 = "-1"
  from_port                = 0
  to_port                  = 0
}

resource "aws_security_group_rule" "ingress_from_self" {
  description       = "Allow all ingress from bastion host"
  security_group_id = aws_security_group.vms_security_group[0].id
  type              = "ingress"
  self              = true
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
}

resource "aws_security_group_rule" "egress_anywhere" {
  description       = "Allow all protocols/ports to everywhere."
  security_group_id = aws_security_group.vms_security_group[0].id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
}
