locals {
  bastion_vpc_cidr             = "10.0.0.0/23"
  control_plane_vpc_cidr       = "10.1.0.0/24"
  pas_vpc_cidr                 = "10.2.0.0/16"
  enterprise_services_vpc_cidr = "10.3.0.0/24"
}

resource "aws_vpc" "bastion_vpc" {
  cidr_block = "${local.bastion_vpc_cidr}"

  tags = {
    Name = "${var.env_name} | bastion vpc"
  }
}

resource "aws_internet_gateway" "bastion_igw" {
  vpc_id = "${aws_vpc.bastion_vpc.id}"

  tags = {
    Name = "${var.env_name} | bastion igw"
  }
}

resource "aws_vpc" "control_plane_vpc" {
  cidr_block = "${local.control_plane_vpc_cidr}"

  tags = {
    Name = "${var.env_name} | control plane vpc"
  }
}

resource "aws_internet_gateway" "control_plane_igw" {
  vpc_id = "${aws_vpc.control_plane_vpc.id}"

  tags = {
    Name = "${var.env_name} | control plane igw"
  }
}

resource "aws_vpc" "pas_vpc" {
  cidr_block = "${local.pas_vpc_cidr}"

  tags = {
    Name = "${var.env_name} | pas vpc"
  }
}

resource "aws_internet_gateway" "pas_igw" {
  vpc_id = "${aws_vpc.pas_vpc.id}"

  tags = {
    Name = "${var.env_name} | pas igw"
  }
}

resource "aws_vpc" "enterprise_services_vpc" {
  cidr_block = "${local.enterprise_services_vpc_cidr}"

  tags = {
    Name = "${var.env_name} | enterprise services vpc"
  }
}

resource "aws_internet_gateway" "enterprise_services_igw" {
  vpc_id = "${aws_vpc.enterprise_services_vpc.id}"

  tags = {
    Name = "${var.env_name} | enterprise services igw"
  }
}

resource "aws_vpc_peering_connection" "bastion_pas" {
  peer_vpc_id = "${aws_vpc.bastion_vpc.id}"
  vpc_id      = "${aws_vpc.pas_vpc.id}"
  auto_accept = true

  tags = {
    Name = "${var.env_name} | bastion/pas vpc peering"
  }
}

resource "aws_vpc_peering_connection" "bastion_enterprise_services" {
  peer_vpc_id = "${aws_vpc.bastion_vpc.id}"
  vpc_id      = "${aws_vpc.enterprise_services_vpc.id}"
  auto_accept = true

  tags = {
    Name = "${var.env_name} | bastion/enterprise services vpc peering"
  }
}

resource "aws_vpc_peering_connection" "bastion_control_plane" {
  peer_vpc_id = "${aws_vpc.bastion_vpc.id}"
  vpc_id      = "${aws_vpc.control_plane_vpc.id}"
  auto_accept = true

  tags = {
    Name = "${var.env_name} | bastion/control plane vpc peering"
  }
}

resource "aws_vpc_peering_connection" "pas_enterprise_services" {
  peer_vpc_id = "${aws_vpc.pas_vpc.id}"
  vpc_id      = "${aws_vpc.enterprise_services_vpc.id}"
  auto_accept = true

  tags = {
    Name = "${var.env_name} | pas/enterprise services vpc peering"
  }
}

resource "aws_vpc_peering_connection" "control_plane_enterprise_services" {
  peer_vpc_id = "${aws_vpc.control_plane_vpc.id}"
  vpc_id      = "${aws_vpc.enterprise_services_vpc.id}"
  auto_accept = true

  tags = {
    Name = "${var.env_name} | control plane/enterprise services vpc peering"
  }
}

resource "aws_vpc_peering_connection" "control_plane_pas" {
  peer_vpc_id = "${aws_vpc.control_plane_vpc.id}"
  vpc_id      = "${aws_vpc.pas_vpc.id}"
  auto_accept = true

  tags = {
    Name = "${var.env_name} | control plane/pas vpc peering"
  }
}

variable "env_name" {
  type = "string"
}