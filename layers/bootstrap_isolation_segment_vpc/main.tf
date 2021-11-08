terraform {
  backend "s3" {}
}

data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "paperwork"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "scaling-params" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "scaling-params"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_control_plane" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_control_plane"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "pas" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "pas"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "routes" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "routes"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

locals {
  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} isolation segment"
  modified_tags = merge(
    var.global_vars["global_tags"],
    {
      "Name"            = local.modified_name
      "MetricsKey"      = data.terraform_remote_state.paperwork.outputs.metrics_key,
      "foundation_name" = data.terraform_remote_state.paperwork.outputs.foundation_name
    },
  )

  isolation_segment_cidr_block_0 = cidrsubnet(data.aws_vpc.vpc.cidr_block, 2, 0)
  isolation_segment_cidr_block_1 = cidrsubnet(data.aws_vpc.vpc.cidr_block, 2, 1)
  isolation_segment_cidr_block_2 = cidrsubnet(data.aws_vpc.vpc.cidr_block, 2, 2)
  isolation_segment_cidr_block_3 = cidrsubnet(data.aws_vpc.vpc.cidr_block, 2, 3)
  // the public subnets make use of the 'extra' space left in each isolation segment cidr
  public_subnet_cidrs = [
    cidrsubnet(local.isolation_segment_cidr_block_0, 2, 3),
    cidrsubnet(local.isolation_segment_cidr_block_1, 2, 3),
    cidrsubnet(local.isolation_segment_cidr_block_2, 2, 3),
  ]

  // the following cidr is unallocated and left for future use
  // unused_cidr = cidrsubnet(local.isolation_segment_cidr_block_3, 2, 3),

  pas_vpc_id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
  cp_vpc_id  = data.terraform_remote_state.paperwork.outputs.cp_vpc_id
  es_vpc_id  = data.terraform_remote_state.paperwork.outputs.es_vpc_id

  iso_s3_endpoint_ids = data.terraform_remote_state.paperwork.outputs.iso_s3_endpoint_ids

  ssh_cidrs           = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_cidrs
  secrets_bucket_name = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
}

data "aws_vpc" "pas_vpc" {
  id = local.pas_vpc_id
}

resource "null_resource" "vpc_tags" {
  triggers = {
    vpc_id   = var.vpc_id
    name     = "${local.env_name} | isolation segment vpc"
    env_name = local.env_name
  }

  provisioner "local-exec" {
    command = "aws ec2 create-tags --resources ${self.triggers.vpc_id} --tags 'Key=Name,Value=${self.triggers.name}' 'Key=Purpose,Value=isolation-segment' 'Key=env_name,Value=${self.triggers.env_name}'"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "aws ec2 delete-tags --resources ${self.triggers.vpc_id} --tags 'Key=Name,Value=${self.triggers.name}' 'Key=Purpose,Value=isolation-segment' 'Key=env_name,Value=${self.triggers.env_name}'"
  }
}

// we can't use the subnet_per_az module because these subnets are not in a contiguous cidr block
resource "aws_subnet" "public_subnets" {
  count      = length(var.availability_zones)
  cidr_block = local.public_subnet_cidrs[count.index]
  vpc_id     = var.vpc_id

  availability_zone = var.availability_zones[count.index]

  tags = local.modified_tags
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

resource "aws_route_table" "public_route_table" {
  vpc_id = var.vpc_id

  tags = local.modified_tags
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public_route_table.id
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

resource "aws_vpc_endpoint_route_table_association" "iso_seg" {
  route_table_id  = aws_route_table.public_route_table.id
  vpc_endpoint_id = lookup(local.iso_s3_endpoint_ids, var.vpc_id)
}


resource "aws_route_table_association" "public_route_table_associations" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

data "template_cloudinit_config" "nat_user_data" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "tag_completion.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.completion_tag_user_data
  }

  part {
    filename     = "clamav.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.amazon2_clamav_user_data
  }

  part {
    filename     = "node_exporter.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.node_exporter_user_data
  }

  part {
    filename     = "banner.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.custom_banner_user_data
  }

  part {
    filename     = "bot_user_accounts_user_data.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.bot_user_accounts_user_data
  }

  part {
    filename     = "iptables.cfg"
    content_type = "text/cloud-config"
    content      = module.iptables_rules.iptables_user_data
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "postfix_client.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.postfix_client_user_data
  }

  # This must be last - updates the AIDE DB after all installations/configurations are complete.
  part {
    filename     = "hardening.cfg"
    content_type = "text/x-include-url"
    content      = data.terraform_remote_state.paperwork.outputs.server_hardening_user_data
  }
}

module "iptables_rules" {
  source                     = "../../modules/iptables"
  nat                        = true
  control_plane_subnet_cidrs = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_cidrs
}

resource "aws_security_group" "vms_security_group" {
  name_prefix = "vms-security-group"
  description = "VMs Security Group"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow ssh/22 from cp"
    cidr_blocks = local.ssh_cidrs
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
  }

  ingress {
    description = "Allow all protocols/ports from within this security group"
    self        = true
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  ingress {
    description     = "Allow all protocols/ports from bosh managed hosts"
    security_groups = [data.terraform_remote_state.pas.outputs.vms_security_group_id]
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
  }

  ingress {
    description     = "Allow ssh/22 from bosh managed hosts"
    security_groups = [data.terraform_remote_state.pas.outputs.om_security_group_id]
    protocol        = "tcp"
    to_port         = 22
    from_port       = 22
  }

  egress {
    description = "Allow all protocols/ports to external hosts"
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  tags = merge(
    local.modified_tags,
    {
      purpose     = "vms-security-group"
      Description = "bootstrap_isolation_segment_vpc"
    },
  )
}

resource "aws_security_group_rule" "pas_ingress_from_isolation_segment" {
  description              = "Allow all iso-seg ports and protocols to reach bosh managed hosts"
  security_group_id        = data.terraform_remote_state.pas.outputs.vms_security_group_id
  source_security_group_id = aws_security_group.vms_security_group.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
}

module "isolation_segment_0" {
  source = "./modules/bootstrap-isolation-segment"

  name               = var.isolation_segment_name_0
  cidr_block         = local.isolation_segment_cidr_block_0
  pas_vpc_cidr_block = data.aws_vpc.pas_vpc.cidr_block

  public_subnet_ids  = aws_subnet.public_subnets.*.id
  vpc_id             = var.vpc_id
  availability_zones = var.availability_zones

  tags           = { tags = local.modified_tags, instance_tags = var.global_vars["instance_tags"] }
  internetless   = var.internetless
  nat_ssh_cidrs  = local.ssh_cidrs
  bot_key_pem    = data.terraform_remote_state.paperwork.outputs.bot_private_key
  instance_types = data.terraform_remote_state.scaling-params.outputs.instance_types
  user_data      = data.template_cloudinit_config.nat_user_data.rendered

  root_domain                = data.terraform_remote_state.paperwork.outputs.root_domain
  syslog_ca_cert             = data.terraform_remote_state.paperwork.outputs.trusted_ca_certs
  ami_id                     = data.terraform_remote_state.paperwork.outputs.amzn_ami_id
  public_bucket_name         = data.terraform_remote_state.paperwork.outputs.public_bucket_name
  public_bucket_url          = data.terraform_remote_state.paperwork.outputs.public_bucket_url
  default_instance_role_name = data.terraform_remote_state.paperwork.outputs.instance_tagger_role_name
  check_cloud_init           = data.terraform_remote_state.paperwork.outputs.check_cloud_init == "false" ? false : true
  operating_system           = data.terraform_remote_state.paperwork.outputs.amazon_operating_system_tag
}

module "isolation_segment_1" {
  source = "./modules/empty-isolation-segment"

  name               = var.isolation_segment_name_1
  cidr_block         = local.isolation_segment_cidr_block_1
  vpc_id             = var.vpc_id
  availability_zones = var.availability_zones
  tags               = local.modified_tags
}

module "isolation_segment_2" {
  source = "./modules/empty-isolation-segment"

  name               = var.isolation_segment_name_2
  cidr_block         = local.isolation_segment_cidr_block_2
  vpc_id             = var.vpc_id
  availability_zones = var.availability_zones
  tags               = local.modified_tags
}

module "isolation_segment_3" {
  source = "./modules/empty-isolation-segment"

  name               = var.isolation_segment_name_3
  cidr_block         = local.isolation_segment_cidr_block_3
  vpc_id             = var.vpc_id
  availability_zones = var.availability_zones
  tags               = local.modified_tags
}

module "route_isolation_segment_pas" {
  source           = "../routes/modules/routing"
  accepter_vpc_id  = var.vpc_id
  requester_vpc_id = local.pas_vpc_id
  accepter_route_table_ids = concat(
    [aws_route_table.public_route_table.id],
    module.isolation_segment_0.private_route_table_ids,
    module.isolation_segment_1.private_route_table_ids,
    module.isolation_segment_2.private_route_table_ids,
    module.isolation_segment_3.private_route_table_ids,
  )
  requester_route_table_ids = concat(
    [data.terraform_remote_state.routes.outputs.pas_public_vpc_route_table_id],
    data.terraform_remote_state.routes.outputs.pas_private_vpc_route_table_ids,
  )
  availability_zones = var.availability_zones
}

module "route_isolation_segment_es" {
  source           = "../routes/modules/routing"
  accepter_vpc_id  = var.vpc_id
  requester_vpc_id = local.es_vpc_id
  accepter_route_table_ids = concat(
    [aws_route_table.public_route_table.id],
    module.isolation_segment_0.private_route_table_ids,
    module.isolation_segment_1.private_route_table_ids,
    module.isolation_segment_2.private_route_table_ids,
    module.isolation_segment_3.private_route_table_ids,
  )
  requester_route_table_ids = concat(
    [data.terraform_remote_state.routes.outputs.es_public_vpc_route_table_id],
    data.terraform_remote_state.routes.outputs.es_private_vpc_route_table_ids,
  )
  availability_zones = var.availability_zones
}

module "route_isolation_segment_control_plane" {
  source           = "../routes/modules/routing"
  accepter_vpc_id  = var.vpc_id
  requester_vpc_id = local.cp_vpc_id
  accepter_route_table_ids = concat(
    [aws_route_table.public_route_table.id],
    module.isolation_segment_0.private_route_table_ids,
    module.isolation_segment_1.private_route_table_ids,
    module.isolation_segment_2.private_route_table_ids,
    module.isolation_segment_3.private_route_table_ids,
  )
  requester_route_table_ids = concat(
    [data.terraform_remote_state.routes.outputs.cp_public_vpc_route_table_id],
    data.terraform_remote_state.routes.outputs.cp_private_vpc_route_table_ids,
  )
  availability_zones = var.availability_zones
}

resource "aws_s3_bucket_object" "blocked-vpc" {
  bucket       = local.secrets_bucket_name
  key          = "blocked-cidrs/iso-seg-${var.vpc_id}"
  content_type = "text/plain"
  content      = data.aws_vpc.vpc.cidr_block
}

output "ssh_host_ips" {
  value = merge(
    module.isolation_segment_0.ssh_host_ips,
    module.isolation_segment_1.ssh_host_ips,
    module.isolation_segment_2.ssh_host_ips,
    module.isolation_segment_3.ssh_host_ips,
  )
}

output "iso_seg_0_nats" {
  value = module.isolation_segment_0.ssh_host_ips
}

output "iso_seg_1_nats" {
  value = module.isolation_segment_1.ssh_host_ips
}

output "iso_seg_2_nats" {
  value = module.isolation_segment_2.ssh_host_ips
}

output "iso_seg_3_nats" {
  value = module.isolation_segment_3.ssh_host_ips
}
