variable "remote_state_region" {
}

variable "remote_state_bucket" {
}

variable "availability_zones" {
  type = list(string)
}

variable "internetless" {
}

variable "vpc_id" {
  type        = string
  description = "ID for Development VPC"
}

data "aws_region" "current" {
}

locals {
  s3_service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  env_name = "Development"
}

resource "aws_vpc_endpoint" "development_s3" {
  vpc_id       = var.vpc_id
  service_name = local.s3_service_name
}

module "development_vpc_route_tables" {
  source                      = "../../modules/vpc_route_tables"
  internetless                = var.internetless
  vpc_id                      = var.vpc_id
  s3_vpc_endpoint_id          = aws_vpc_endpoint.development_s3.id
  availability_zones          = var.availability_zones
  enable_s3_vpc_endpoint      = true
  create_private_route_tables = false

  tags = merge(
    {
      Name = "${local.env_name} | DEVELOPMENT",
      env = local.env_name
    }
  )
}