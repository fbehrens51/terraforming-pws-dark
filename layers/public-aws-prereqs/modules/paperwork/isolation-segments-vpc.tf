locals {
  isolation_segment_vpc_cidr = "10.4.0.0/24"
}

resource "aws_vpc" "isolation_segment_vpc" {
  cidr_block = local.isolation_segment_vpc_cidr

  tags = {
    Name     = "${var.env_name} | isolation segment vpc"
    Purpose  = "isolation-segment"
    env_name = var.env_name
  }

  lifecycle {
    ignore_changes = [
      # tags are updated in the bootstrap_isolation_segments to work onsite.
      tags,
    ]
  }
}

resource "aws_internet_gateway" "isolation_segment_igw" {
  vpc_id = aws_vpc.isolation_segment_vpc.id

  tags = {
    Name = "${var.env_name} | isolation_segment igw"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_vpc_peering_connection" "isolation_segment_cp" {
  peer_vpc_id = aws_vpc.isolation_segment_vpc.id
  vpc_id      = aws_vpc.control_plane_vpc.id
  auto_accept = true

  tags = {
    Name = "${var.env_name} | isolation segment/cp vpc peering"
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_vpc_peering_connection" "isolation_segment_pas" {
  peer_vpc_id = aws_vpc.isolation_segment_vpc.id
  vpc_id      = aws_vpc.pas_vpc.id
  auto_accept = true

  tags = {
    Name = "${var.env_name} | isolation segment/pas vpc peering"
  }
  lifecycle {
    ignore_changes = [tags]
  }
}

resource "aws_vpc_peering_connection" "isolation_segment_enterprise_services" {
  peer_vpc_id = aws_vpc.isolation_segment_vpc.id
  vpc_id      = aws_vpc.enterprise_services_vpc.id
  auto_accept = true

  tags = {
    Name = "${var.env_name} | isolation segment/enterprise services vpc peering"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}
