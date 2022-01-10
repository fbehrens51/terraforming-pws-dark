locals {
  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} tkg"
  modified_tags = merge(
  var.global_vars["global_tags"],
  var.global_vars["instance_tags"],
  {
    "Name"            = local.modified_name
    "MetricsKey"      = data.terraform_remote_state.paperwork.outputs.metrics_key
    "foundation_name" = data.terraform_remote_state.paperwork.outputs.foundation_name
    "job"             = "jumpbox"
  },
  )
  root_domain   = data.terraform_remote_state.paperwork.outputs.root_domain
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

data "terraform_remote_state" "bootstrap_sjb" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_sjb"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_tkgjb" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_tkgjb"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_tkg" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_tkg"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "terraform_remote_state" "bootstrap_control_plane_foundation" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "bootstrap_control_plane_foundation"
    region  = var.remote_state_region
    encrypt = true
  }
}

locals {
  release_channel             = data.terraform_remote_state.paperwork.outputs.release_channel
  secret_bucket_name          = data.terraform_remote_state.paperwork.outputs.secrets_bucket_name
  artifact_repo_bucket_name   = data.terraform_remote_state.paperwork.outputs.artifact_repo_bucket_name
  artifact_repo_bucket_region = data.terraform_remote_state.paperwork.outputs.artifact_repo_bucket_region
  terraform_bucket_name       = data.terraform_remote_state.bootstrap_sjb.outputs.terraform_bucket_name
  ldap_dn                     = data.terraform_remote_state.paperwork.outputs.ldap_dn
  ldap_port                   = data.terraform_remote_state.paperwork.outputs.ldap_port
  ldap_host                   = data.terraform_remote_state.paperwork.outputs.ldap_host
  ldap_basedn                 = data.terraform_remote_state.paperwork.outputs.ldap_basedn
  ldap_ca_cert                = data.terraform_remote_state.paperwork.outputs.ldap_ca_cert_s3_path
  ldap_client_cert            = data.terraform_remote_state.paperwork.outputs.ldap_client_cert_s3_path
  ldap_client_key             = data.terraform_remote_state.paperwork.outputs.ldap_client_key_s3_path
  pypi_protocol               = var.pypi_host_secure ? "https" : "http"
}

data "aws_vpc" "vpc" {
  id = data.terraform_remote_state.paperwork.outputs.tkg_vpc_id
}

//resource "aws_internet_gateway" "igw" {
//  vpc_id = data.aws_vpc.vpc.id
//}
//
//resource "aws_route_table" "public" {
//  vpc_id = data.aws_vpc.vpc.id
//}

//resource "aws_route" "internet" {
//  destination_cidr_block = "0.0.0.0/0"
//  route_table_id         = aws_route_table.public.id
//  gateway_id             = aws_internet_gateway.
//}

module "dnsmasq" {
  source         = "../../modules/dnsmasq"
  enterprise_dns = data.terraform_remote_state.paperwork.outputs.enterprise_dns
  forwarders     = [{
    domain        = var.endpoint_domain
    forwarder_ips = [cidrhost(data.aws_vpc.vpc.cidr_block, 2)]
  },
    {
      domain        = ""
      forwarder_ips = data.terraform_remote_state.paperwork.outputs.enterprise_dns
    }
  ]
}

module "iptables_rules" {
  source                     = "../../modules/iptables"
  control_plane_subnet_cidrs = data.terraform_remote_state.bootstrap_control_plane.outputs.control_plane_subnet_cidrs
}

resource "aws_security_group" tkgjb {
  vpc_id = data.aws_vpc.vpc.id
}

resource "aws_security_group_rule" tkgjb_https {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.tkgjb.id
}

resource "aws_security_group_rule" tkgjb_ssh {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.tkgjb.id
}

resource "aws_security_group_rule" tkgjb_self {
  type              = "ingress"
  self              = true
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.tkgjb.id
}

resource "aws_security_group_rule" tkgjb_egress {
  type              = "egress"
  from_port         = 0
  to_port           = 65000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.tkgjb.id
}

data "aws_subnet_ids" tkgjb_subnet {
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name   = "tag:Name"
    values = ["*tkgjb*"]
  }

  filter {
    name   = "availability-zone"
    values = [var.singleton_availability_zone]
  }
}

//resource "aws_route_table_association" public {
//  route_table_id = aws_route_table.public.id
//  subnet_id      = tolist(data.aws_subnet_ids.tkgjb_subnet.ids)[0]
//}

resource "aws_ebs_volume" "tkgjb_home" {
  availability_zone = var.singleton_availability_zone
  size              = 60
  encrypted         = true
  kms_key_id        = data.terraform_remote_state.paperwork.outputs.kms_key_arn
}

resource "aws_volume_attachment" "volume_attachment" {
  skip_destroy = true
  instance_id  = aws_instance.tkgjb.id
  volume_id    = aws_ebs_volume.tkgjb_home.id
  device_name  = "/dev/sdf"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "aws_key_pair" "key_pair" {
  key_name   = "tkgjb-temp-key"
  public_key = tls_private_key.private_key.public_key_openssh
}

resource "aws_instance" "tkgjb" {
  ami                         = data.terraform_remote_state.paperwork.outputs.amzn_ami_id
  subnet_id                   = tolist(data.aws_subnet_ids.tkgjb_subnet.ids)[0]
  instance_type               = "m5.4xlarge"
  iam_instance_profile        = data.terraform_remote_state.paperwork.outputs.bootstrap_role_name
  key_name                    = "neva_mbp"
  vpc_security_group_ids      = [aws_security_group.tkgjb.id]
  user_data                   = data.template_cloudinit_config.user_data.rendered
  associate_public_ip_address = true

  root_block_device {
    volume_size = 1000
  }

  tags = merge(local.modified_tags,
  {
    Name = "${local.env_name}-tkgjb"
  })
}
