variable "vpc_id" {
}

variable "s3_vpc_endpoint_id" {
}

variable "availability_zones" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}

locals {
  env_name    = var.tags["Name"]
  public_name = "${local.env_name} PUBLIC"
  public_tags = merge(
    var.tags,
    {
      "Name" = local.public_name
    },
  )

  private_name = "${local.env_name} PRIVATE"
  private_tags = merge(
    var.tags,
    {
      "Name" = local.private_name
    },
  )
}

variable "internetless" {
}

data "aws_internet_gateway" "igw" {
  count = var.internetless ? 0 : 1

  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_vpn_gateway" "vgw" {
  count = var.internetless ? 1 : 0

  attached_vpc_id = var.vpc_id
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public_route_table[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = element(
    concat(
      data.aws_internet_gateway.igw.*.internet_gateway_id,
      data.aws_vpn_gateway.vgw.*.id,
    ),
    0,
  )

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table" "public_route_table" {
  count = 1

  vpc_id = var.vpc_id

  tags = local.public_tags
}

resource "aws_vpc_endpoint_route_table_association" "public_s3_vpc_endpoint" {
  vpc_endpoint_id = var.s3_vpc_endpoint_id
  route_table_id  = aws_route_table.public_route_table[0].id
}

resource "aws_route_table" "private_route_table" {
  count = length(var.availability_zones)

  vpc_id = var.vpc_id

  tags = local.private_tags
}

resource "aws_vpc_endpoint_route_table_association" "private_s3_vpc_endpoint" {
  count           = length(var.availability_zones)
  vpc_endpoint_id = var.s3_vpc_endpoint_id
  route_table_id  = element(aws_route_table.private_route_table.*.id, count.index)
}

output "public_route_table_id" {
  value = aws_route_table.public_route_table[0].id
}

output "private_route_table_ids" {
  value = aws_route_table.private_route_table.*.id
}

