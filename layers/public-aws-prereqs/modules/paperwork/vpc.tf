locals {
  bastion_vpc_cidr             = "10.0.0.0/23"
  control_plane_vpc_cidr       = "10.1.0.0/24"
  pas_vpc_cidr                 = "10.2.0.0/16"
  enterprise_services_vpc_cidr = "10.3.0.0/24"
}

resource "aws_ec2_transit_gateway" "tgw" {
  count                           = var.internetless ? 1 : 0
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"

  tags = {
    Name = "${var.env_name} | tgw"
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_vpc" "bastion_vpc" {
  cidr_block = local.bastion_vpc_cidr

  tags = {
    Name = "${var.env_name} | bastion vpc"
  }
  lifecycle {
    ignore_changes = [tags]
  }

}

resource "aws_internet_gateway" "bastion_igw" {
  vpc_id = aws_vpc.bastion_vpc.id

  tags = {
    Name = "${var.env_name} | bastion igw"
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_vpc" "control_plane_vpc" {
  cidr_block = local.control_plane_vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.env_name} | control plane vpc"
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_internet_gateway" "control_plane_igw" {
  vpc_id = aws_vpc.control_plane_vpc.id

  tags = {
    Name = "${var.env_name} | control plane igw"
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_vpc" "pas_vpc" {
  cidr_block = local.pas_vpc_cidr

  tags = {
    Name = "${var.env_name} | pas vpc"
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_internet_gateway" "pas_igw" {
  vpc_id = aws_vpc.pas_vpc.id

  tags = {
    Name = "${var.env_name} | pas igw"
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_vpc" "enterprise_services_vpc" {
  cidr_block = local.enterprise_services_vpc_cidr

  tags = {
    Name = "${var.env_name} | enterprise services vpc"
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_internet_gateway" "enterprise_services_igw" {
  vpc_id = aws_vpc.enterprise_services_vpc.id

  tags = {
    Name = "${var.env_name} | enterprise services igw"
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_vpc_peering_connection" "bastion_control_plane" {
  peer_vpc_id = aws_vpc.bastion_vpc.id
  vpc_id      = aws_vpc.control_plane_vpc.id
  auto_accept = true

  tags = {
    Name = "${var.env_name} | bastion/control plane vpc peering"
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_vpc_peering_connection" "pas_enterprise_services" {
  peer_vpc_id = aws_vpc.pas_vpc.id
  vpc_id      = aws_vpc.enterprise_services_vpc.id
  auto_accept = true

  tags = {
    Name = "${var.env_name} | pas/enterprise services vpc peering"
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_vpc_peering_connection" "control_plane_enterprise_services" {
  peer_vpc_id = aws_vpc.control_plane_vpc.id
  vpc_id      = aws_vpc.enterprise_services_vpc.id
  auto_accept = true

  tags = {
    Name = "${var.env_name} | control plane/enterprise services vpc peering"
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_vpc_peering_connection" "control_plane_pas" {
  peer_vpc_id = aws_vpc.control_plane_vpc.id
  vpc_id      = aws_vpc.pas_vpc.id
  auto_accept = true

  tags = {
    Name = "${var.env_name} | control plane/pas vpc peering"
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_vpc_peering_connection" "control_plane_iso1" {
  peer_vpc_id = aws_vpc.isolation_segment_vpc.id
  vpc_id      = aws_vpc.control_plane_vpc.id
  auto_accept = true

  tags = {
    Name = "${var.env_name} | control plane/iso1 vpc peering"
  }
  lifecycle {
    ignore_changes = [tags]
  }
}
