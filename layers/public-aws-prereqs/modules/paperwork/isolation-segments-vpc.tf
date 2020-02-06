locals {
  isolation_segment_vpc_cidr = "10.4.0.0/24"
}

resource "aws_vpc" "isolation_segment_vpc" {
  cidr_block = local.isolation_segment_vpc_cidr

  tags = {
    Name    = "${var.env_name} | isolation segment vpc"
    Purpose = "isolation-segment"
  }
}

resource "aws_vpn_gateway" "isolation_segment_vgw" {
  vpc_id = aws_vpc.isolation_segment_vpc.id

  tags = {
    Name = "${var.env_name} | isolation segment vgw"
  }
}

resource "aws_internet_gateway" "isolation_segment_igw" {
  vpc_id = aws_vpc.isolation_segment_vpc.id

  tags = {
    Name = "${var.env_name} | isolation_segment igw"
  }
}

resource "aws_vpc_peering_connection" "isolation_segment_bastion" {
  peer_vpc_id = aws_vpc.isolation_segment_vpc.id
  vpc_id      = aws_vpc.bastion_vpc.id
  auto_accept = true

  tags = {
    Name = "${var.env_name} | isolation segment/bastion vpc peering"
  }
}

resource "aws_vpc_peering_connection" "isolation_segment_pas" {
  peer_vpc_id = aws_vpc.isolation_segment_vpc.id
  vpc_id      = aws_vpc.pas_vpc.id
  auto_accept = true

  tags = {
    Name = "${var.env_name} | isolation segment/pas vpc peering"
  }
}

resource "aws_vpc_peering_connection" "isolation_segment_enterprise_services" {
  peer_vpc_id = aws_vpc.isolation_segment_vpc.id
  vpc_id      = aws_vpc.enterprise_services_vpc.id
  auto_accept = true

  tags = {
    Name = "${var.env_name} | isolation segment/enterprise services vpc peering"
  }
}
