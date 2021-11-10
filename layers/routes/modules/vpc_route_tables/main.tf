variable "vpc_id" {
}

variable "s3_vpc_endpoint_id" {
}

variable "enable_s3_vpc_endpoint" {
  type    = bool
  default = true
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
  type = bool
}

data "aws_internet_gateway" "igw" {
  count = var.internetless ? 0 : 1
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_vpn_gateway" "vgw" {
  count           = var.internetless ? 1 : 0
  attached_vpc_id = var.vpc_id
}

resource "aws_route" "default_route" {
  count                  = var.internetless ? 0 : 1
  route_table_id         = aws_route_table.public_route_table[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = data.aws_internet_gateway.igw.0.internet_gateway_id
  timeouts {
    create = "5m"
  }
}

resource "aws_route_table" "public_route_table" {
  count            = 1
  vpc_id           = var.vpc_id
  tags             = local.public_tags
  propagating_vgws = var.internetless ? [data.aws_vpn_gateway.vgw.0.id] : []
}

resource "aws_vpc_endpoint_route_table_association" "public_s3_vpc_endpoint" {
  count           = var.enable_s3_vpc_endpoint ? 1 : 0
  vpc_endpoint_id = var.s3_vpc_endpoint_id
  route_table_id  = aws_route_table.public_route_table[0].id
}

resource "aws_route_table" "private_route_table" {
  count  = length(var.availability_zones)
  vpc_id = var.vpc_id
  tags   = local.private_tags
}

resource "aws_vpc_endpoint_route_table_association" "private_s3_vpc_endpoint" {
  count           = var.enable_s3_vpc_endpoint ? length(var.availability_zones) : 0
  vpc_endpoint_id = var.s3_vpc_endpoint_id
  route_table_id  = element(aws_route_table.private_route_table.*.id, count.index)
}

output "public_route_table_id" {
  value = aws_route_table.public_route_table[0].id
}

output "private_route_table_ids" {
  value = aws_route_table.private_route_table.*.id
}

