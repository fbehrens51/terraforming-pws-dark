data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "paperwork"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "aws_vpc" "vpc" {
  id = data.terraform_remote_state.paperwork.outputs.cp_vpc_id
}

data "aws_route_tables" "cp_private_route_tables" {
  vpc_id = data.terraform_remote_state.paperwork.outputs.cp_vpc_id
  tags = merge(var.global_vars["global_tags"],{"Type"="PRIVATE"})
}

data "aws_route_table" "cp_public_route_table" {
  vpc_id = data.terraform_remote_state.paperwork.outputs.cp_vpc_id
  tags = merge(var.global_vars["global_tags"],{"Type"="PUBLIC"})
}

module "public_subnets" {
  source             = "../../modules/subnet_per_az"
  availability_zones = var.availability_zones
  vpc_id             = data.aws_vpc.vpc.id
  cidr_block         = local.public_cidr_block
  tags = merge(
    local.modified_tags,
    {
      "Name" = "${local.modified_name}-public"
    },
  )
}

resource "aws_route_table_association" "public_route_table_assoc" {
  count          = length(var.availability_zones)
  subnet_id      = module.public_subnets.subnet_ids[count.index]
  route_table_id = data.aws_route_table.cp_public_route_table.id
}

module "private_subnets" {
  source             = "../../modules/subnet_per_az"
  availability_zones = var.availability_zones
  vpc_id             = data.aws_vpc.vpc.id
  cidr_block         = local.private_cidr_block
  tags = merge(
    local.modified_tags,
    {
      "Name" = "${local.modified_name}-private"
    },
  )
}

resource "aws_route_table_association" "private_route_table_assoc" {
  count          = length(var.availability_zones)
  subnet_id      = module.private_subnets.subnet_ids[count.index]
  route_table_id = tolist(data.aws_route_tables.cp_private_route_tables.ids)[count.index]
}

resource "aws_security_group" "vms_security_group" {
  count = 1

  name        = "vms_security_group"
  description = "VMs Security Group"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    description = "Allow all traffic from within the control plane"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  ingress {
    description = "Allow metrics scraping from Healthwatch"
    cidr_blocks = [data.aws_vpc.pas_vpc.cidr_block]
    protocol    = "tcp"
    from_port   = 53035
    to_port     = 53035
  }

  egress {
    description = "Allow all portocols/ports to everywhere"
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  tags = merge(
    local.modified_tags,
    {
      Name        = "${local.env_name}-vms-security-group"
      Description = "bootstrap_control_plane"
    },
  )
}

data "aws_vpc" "pas_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
}

data "aws_region" "current" {
}

locals {

  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} control plane"
  modified_tags = merge(
    var.global_vars["global_tags"],
    {
      "Name"            = local.modified_name
      "MetricsKey"      = data.terraform_remote_state.paperwork.outputs.metrics_key,
      "foundation_name" = data.terraform_remote_state.paperwork.outputs.foundation_name
    },
  )

  public_cidr_block  = cidrsubnet(data.aws_vpc.vpc.cidr_block, 1, 0)
  rds_cidr_block     = cidrsubnet(local.public_cidr_block, 2, 3)
  private_cidr_block = cidrsubnet(data.aws_vpc.vpc.cidr_block, 1, 1)
  sjb_cidr_block     = cidrsubnet(local.private_cidr_block, 2, 3)

  ec2_service_name = "${var.vpce_interface_prefix}${data.aws_region.current.name}.ec2"

}


resource "aws_vpc_endpoint" "cp_ec2" {
  vpc_id              = data.aws_vpc.vpc.id
  service_name        = local.ec2_service_name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = aws_security_group.vms_security_group.*.id
  subnet_ids          = module.private_subnets.subnet_ids
  private_dns_enabled = true
  tags                = local.modified_tags
}

resource "aws_vpc_dhcp_options" "cp_dhcp_options" {
  domain_name_servers = data.terraform_remote_state.paperwork.outputs.enterprise_dns
  //  ntp_servers = []
  tags = {
    name = "CP DHCP Options"
  }
}

resource "aws_vpc_dhcp_options_association" "cp_dhcp_options_assoc" {
  dhcp_options_id = aws_vpc_dhcp_options.cp_dhcp_options.id
  vpc_id          = data.aws_vpc.vpc.id
  depends_on      = [aws_vpc_dhcp_options.cp_dhcp_options]
}

