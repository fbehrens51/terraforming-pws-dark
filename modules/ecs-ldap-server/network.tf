
data "aws_availability_zones" "available" {
  state = "available"
}

resource aws_vpc vpc {
  cidr_block = "10.255.0.0/16"
  tags = {
    Name = "eagle-ecs"
  }
}

locals {
  public_cidr  = cidrsubnet(aws_vpc.vpc.cidr_block, 4, 0)
  private_cidr = cidrsubnet(aws_vpc.vpc.cidr_block, 4, 1)
}

resource aws_subnet public {
  count             = 3
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(local.public_cidr, 4, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource aws_subnet private {
  count             = 3
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(local.private_cidr, 4, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource aws_security_group ldap {
  vpc_id = aws_vpc.vpc.id
}

resource aws_security_group_rule ldap {
  type              = "ingress"
  from_port         = local.ldap_port
  to_port           = local.ldap_port
  protocol          = "tcp"
  cidr_blocks       = aws_subnet.public.*.cidr_block
  security_group_id = aws_security_group.ldap.id
}

resource aws_security_group_rule ldap_egress {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ldap.id
}

resource aws_security_group nlb {
  vpc_id = aws_vpc.vpc.id
}

resource aws_security_group_rule nlb {
  type              = "ingress"
  from_port         = local.ldap_port
  to_port           = local.ldap_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nlb.id
}

resource aws_security_group_rule nlb_egress {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.nlb.id
}

resource aws_internet_gateway igw {
  vpc_id = aws_vpc.vpc.id
}

resource aws_route_table public {
  vpc_id = aws_vpc.vpc.id
}

resource aws_route_table_association public {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource aws_route public {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.igw.id
}

resource aws_route_table private {
  vpc_id = aws_vpc.vpc.id
}

resource aws_route_table_association private {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource aws_eip nat {}

resource aws_nat_gateway nat {
  subnet_id     = aws_subnet.public[0].id
  allocation_id = aws_eip.nat.id
}

resource aws_route private {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = aws_nat_gateway.nat.id
}
