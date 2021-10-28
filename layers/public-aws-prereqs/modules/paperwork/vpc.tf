locals {
  bastion_vpc_cidr             = "10.0.0.0/23"
  control_plane_vpc_cidr       = "10.1.0.0/24"
  pas_vpc_cidr                 = "10.2.0.0/16"
  enterprise_services_vpc_cidr = "10.3.0.0/24"
  // iso_seg_cidr = 10.4.0.0/24
  tkg_vpc_cidr                 = "10.5.0.0/24"
}

resource "aws_vpc" "bastion_vpc" {
  cidr_block = local.bastion_vpc_cidr

  tags = {
    Name = "${var.env_name} | bastion vpc"
  }
}

resource "aws_vpn_gateway" "bastion_vgw" {
  vpc_id = aws_vpc.bastion_vpc.id

  tags = {
    Name = "${var.env_name} | bastion vgw"
  }
}

resource "aws_internet_gateway" "bastion_igw" {
  vpc_id = aws_vpc.bastion_vpc.id

  tags = {
    Name = "${var.env_name} | bastion igw"
  }
}

resource "aws_vpc" "control_plane_vpc" {
  cidr_block = local.control_plane_vpc_cidr

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.env_name} | control plane vpc"
  }
}

resource "aws_vpn_gateway" "control_plane_vgw" {
  vpc_id = aws_vpc.control_plane_vpc.id

  tags = {
    Name = "${var.env_name} | control plane vgw"
  }
}

resource "aws_internet_gateway" "control_plane_igw" {
  vpc_id = aws_vpc.control_plane_vpc.id

  tags = {
    Name = "${var.env_name} | control plane igw"
  }
}

resource "aws_vpc" "pas_vpc" {
  cidr_block = local.pas_vpc_cidr

  tags = {
    Name = "${var.env_name} | pas vpc"
  }
}

resource "aws_vpn_gateway" "pas_vgw" {
  vpc_id = aws_vpc.pas_vpc.id

  tags = {
    Name = "${var.env_name} | pas vgw"
  }
}

resource "aws_internet_gateway" "pas_igw" {
  vpc_id = aws_vpc.pas_vpc.id

  tags = {
    Name = "${var.env_name} | pas igw"
  }
}

resource "aws_vpc" "enterprise_services_vpc" {
  cidr_block = local.enterprise_services_vpc_cidr

  tags = {
    Name = "${var.env_name} | enterprise services vpc"
  }
}

resource "aws_vpn_gateway" "enterprise_services_vgw" {
  vpc_id = aws_vpc.enterprise_services_vpc.id

  tags = {
    Name = "${var.env_name} | enterprise services vgw"
  }
}

resource "aws_internet_gateway" "enterprise_services_igw" {
  vpc_id = aws_vpc.enterprise_services_vpc.id

  tags = {
    Name = "${var.env_name} | enterprise services igw"
  }
}

resource "aws_vpc" "tkg_vpc" {
  count      = var.enable_tkg ? 1 : 0
  cidr_block = local.tkg_vpc_cidr

  tags = {
    Name = "${var.env_name} | tkg vpc"
  }
}

resource "aws_vpn_gateway" "tkg_vgw" {
  count  = var.enable_tkg ? 1 : 0
  vpc_id = aws_vpc.tkg_vpc[count.index].id

  tags = {
    Name = "${var.env_name} | tkg vgw"
  }
}

resource "aws_internet_gateway" "tkg_igw" {
  count  = var.enable_tkg ? 1 : 0
  vpc_id = aws_vpc.tkg_vpc[count.index].id

  tags = {
    Name = "${var.env_name} | tkg igw"
  }
}

resource "aws_vpc_peering_connection" "bastion_control_plane" {
  peer_vpc_id = aws_vpc.bastion_vpc.id
  vpc_id      = aws_vpc.control_plane_vpc.id
  auto_accept = true

  tags = {
    Name = "${var.env_name} | bastion/control plane vpc peering"
  }
}

resource "aws_vpc_peering_connection" "pas_enterprise_services" {
  peer_vpc_id = aws_vpc.pas_vpc.id
  vpc_id      = aws_vpc.enterprise_services_vpc.id
  auto_accept = true

  tags = {
    Name = "${var.env_name} | pas/enterprise services vpc peering"
  }
}

resource "aws_vpc_peering_connection" "control_plane_enterprise_services" {
  peer_vpc_id = aws_vpc.control_plane_vpc.id
  vpc_id      = aws_vpc.enterprise_services_vpc.id
  auto_accept = true

  tags = {
    Name = "${var.env_name} | control plane/enterprise services vpc peering"
  }
}

resource "aws_vpc_peering_connection" "control_plane_pas" {
  peer_vpc_id = aws_vpc.control_plane_vpc.id
  vpc_id      = aws_vpc.pas_vpc.id
  auto_accept = true

  tags = {
    Name = "${var.env_name} | control plane/pas vpc peering"
  }
}

resource "aws_vpc_peering_connection" "control_plane_iso1" {
  peer_vpc_id = aws_vpc.isolation_segment_vpc.id
  vpc_id      = aws_vpc.control_plane_vpc.id
  auto_accept = true

  tags = {
    Name = "${var.env_name} | control plane/iso1 vpc peering"
  }
}

resource "aws_vpc_peering_connection" "tkg_control_plane" {
  count       = var.enable_tkg ? 1 : 0
  peer_vpc_id = aws_vpc.control_plane_vpc.id
  vpc_id      = aws_vpc.tkg_vpc[count.index].id
  auto_accept = true

  tags = {
    Name = "${var.env_name} | tkg/control plane vpc peering"
  }
}

resource "aws_vpc_peering_connection" "tkg_pas" {
  count       = var.enable_tkg ? 1 : 0
  peer_vpc_id = aws_vpc.pas_vpc.id
  vpc_id      = aws_vpc.tkg_vpc[count.index].id
  auto_accept = true

  tags = {
    Name = "${var.env_name} | tkg/pas vpc peering"
  }
}

resource "aws_vpc_peering_connection" "tkg_es" {
  count       = var.enable_tkg ? 1 : 0
  peer_vpc_id = aws_vpc.enterprise_services_vpc.id
  vpc_id      = aws_vpc.tkg_vpc[count.index].id
  auto_accept = true

  tags = {
    Name = "${var.env_name} | tkg/enterprise services vpc peering"
  }
}
