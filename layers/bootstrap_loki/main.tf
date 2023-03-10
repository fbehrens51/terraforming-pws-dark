data "terraform_remote_state" "paperwork" {
  backend = "s3"

  config = {
    bucket  = var.remote_state_bucket
    key     = "paperwork"
    region  = var.remote_state_region
    encrypt = true
  }
}

data "aws_vpc" "pas_vpc" {
  id = data.terraform_remote_state.paperwork.outputs.pas_vpc_id
}

module "domains" {
  source      = "../../modules/domains"
  root_domain = data.terraform_remote_state.paperwork.outputs.root_domain
}

module "syslog_ports" {
  source = "../../modules/syslog_ports"
}


module "es_public_subnets" {
  source      = "../../modules/get_subnets_by_tag"
  global_vars = var.global_vars
  vpc_id      = data.terraform_remote_state.paperwork.outputs.es_vpc_id
  subnet_type = "PUBLIC"
}

module "es_private_subnets" {
  source      = "../../modules/get_subnets_by_tag"
  global_vars = var.global_vars
  vpc_id      = data.terraform_remote_state.paperwork.outputs.es_vpc_id
  subnet_type = "PRIVATE"
}

locals {
  env_name      = var.global_vars.env_name
  modified_name = "${local.env_name} loki"
  modified_tags = merge(
    var.global_vars["global_tags"],
    {
      "Name" = local.modified_name
    },
  )

  private_subnets = module.es_private_subnets.subnet_ids_sorted_by_az
  public_subnets  = module.es_public_subnets.subnet_ids_sorted_by_az
  public_subnet   = module.es_public_subnets.subnet_ids_sorted_by_az[0]

  loki_ingress_rules = [
    {
      description = "Allow ssh/22 from everywhere"
      port        = "22"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      # TODO: this should be open only internally
      description = "Allow http/${module.syslog_ports.loki_http_port} from everywhere"
      port        = module.syslog_ports.loki_http_port
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      description = "Allow http/${module.syslog_ports.loki_healthcheck_port} (healthcheck) from the load balancer"
      port        = module.syslog_ports.loki_healthcheck_port
      protocol    = "tcp"
      cidr_blocks = join(",", data.aws_subnet.public_subnets.*.cidr_block)

    },
    {
      // node_exporter metrics endpoint for grafana
      description = "Allow node_exporter/9100 from pas_vpc"
      port        = "9100"
      protocol    = "tcp"
      cidr_blocks = data.aws_vpc.pas_vpc.cidr_block
    },
  ]

  loki_egress_rules = [
    {
      description = "Allow all protocols/ports to everywhere"
      port        = "0"
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  loki_internal_ports = [
    {
      description = "Allow loki memberlist coordination"
      port        = module.syslog_ports.loki_bind_port
      protocol    = "tcp"
    },
    {
      description = "Allow loki internal grpc coordination"
      port        = module.syslog_ports.loki_grpc_port
      protocol    = "tcp"
    },
  ]


  formatted_env_name = replace(local.env_name, " ", "-")

  s3_logs_bucket = data.terraform_remote_state.paperwork.outputs.s3_logs_bucket

  loki_storage_bucket = "${local.formatted_env_name}-loki-storage"

  loki_lb_name = "${local.formatted_env_name}-loki-lb"

  director_role_id    = data.terraform_remote_state.paperwork.outputs.director_role_id
  om_role_id          = data.terraform_remote_state.paperwork.outputs.om_role_id
  sjb_role_id         = data.terraform_remote_state.paperwork.outputs.sjb_role_id
  concourse_role_id   = data.terraform_remote_state.paperwork.outputs.concourse_role_id
  bosh_role_id        = data.terraform_remote_state.paperwork.outputs.bosh_role_id
  isse_role_id        = data.terraform_remote_state.paperwork.outputs.isse_role_id
  super_user_ids      = data.terraform_remote_state.paperwork.outputs.super_user_ids
  super_user_role_ids = data.terraform_remote_state.paperwork.outputs.super_user_role_ids

  bootstrap_role_id  = data.terraform_remote_state.paperwork.outputs.bootstrap_role_id
  foundation_role_id = data.terraform_remote_state.paperwork.outputs.foundation_role_id
}

data "aws_subnet" "public_subnets" {
  count = length(local.public_subnets)
  id    = local.public_subnets[count.index]
}

data "aws_subnet" "private_subnets" {
  count = length(local.private_subnets)
  id    = local.private_subnets[count.index]
}

data "aws_iam_role" "loki" {
  name = data.terraform_remote_state.paperwork.outputs.loki_role_name
}

resource "aws_s3_bucket" "loki_storage" {
  bucket        = local.loki_storage_bucket
  acl           = "private"
  tags          = local.modified_tags
  force_destroy = var.force_destroy_buckets

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  logging {
    target_bucket = local.s3_logs_bucket
    target_prefix = "${local.loki_storage_bucket}/"
  }
}

module "loki_storage_bucket_policy" {
  source              = "../../modules/bucket/policy/generic"
  bucket_arn          = aws_s3_bucket.loki_storage.arn
  read_write_role_ids = [data.aws_iam_role.loki.unique_id]
  read_only_role_ids = concat(local.super_user_role_ids, [
    local.director_role_id,
    local.om_role_id,
    local.bosh_role_id,
    local.sjb_role_id,
    local.concourse_role_id,
    local.bootstrap_role_id,
    local.foundation_role_id
  ], [local.isse_role_id])
  read_only_user_ids = local.super_user_ids
  # loki's compactor needs to delete objects over time for log retention limits
  disable_delete = false
}

resource "aws_s3_bucket_policy" "loki_storage_bucket_policy_attachment" {
  bucket = aws_s3_bucket.loki_storage.bucket
  policy = module.loki_storage_bucket_policy.json
}

resource "aws_ebs_volume" "loki_data" {
  count             = length(local.private_subnets)
  availability_zone = element(data.aws_subnet.private_subnets.*.availability_zone, count.index)
  size              = 100
  encrypted         = true
  kms_key_id        = data.terraform_remote_state.paperwork.outputs.kms_key_arn
}

resource "aws_lb" "loki_lb" {
  name                             = local.loki_lb_name
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = local.public_subnets
  enable_cross_zone_load_balancing = true
  tags = merge(
    local.modified_tags,
    {
      "Name" = local.loki_lb_name
    },
  )
}

resource "aws_lb_target_group" "loki_nlb_http" {
  name_prefix = "http"
  port        = module.syslog_ports.loki_http_port
  protocol    = "TCP"
  vpc_id      = data.terraform_remote_state.paperwork.outputs.es_vpc_id

  tags = {
    Name = "${local.formatted_env_name}-loki${module.syslog_ports.loki_http_port}"
  }

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    port = module.syslog_ports.loki_healthcheck_port
    path = "/ready"
  }
}

resource "aws_lb_listener" "loki_nlb_http" {
  load_balancer_arn = aws_lb.loki_lb.arn
  protocol          = "TCP"
  port              = module.syslog_ports.loki_http_port

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.loki_nlb_http.arn
  }
}

module "bootstrap" {
  source         = "../../modules/eni_per_subnet"
  ingress_rules  = local.loki_ingress_rules
  egress_rules   = local.loki_egress_rules
  internal_ports = local.loki_internal_ports
  subnet_ids     = local.private_subnets
  create_eip     = "false"
  eni_count      = "3"
  tags           = local.modified_tags
}

resource "random_string" "loki_password" {
  length  = "32"
  special = false
}

variable "remote_state_region" {
}

variable "remote_state_bucket" {
}

variable "force_destroy_buckets" {
  type    = bool
  default = false
}

variable "global_vars" {
  type = any
}

output "loki_eni_ids" {
  value = module.bootstrap.eni_ids
}

output "volume_id" {
  value = aws_ebs_volume.loki_data.*.id
}

output "loki_http_target_group" {
  value = aws_lb_target_group.loki_nlb_http.arn
}

output "loki_eni_ips" {
  value = module.bootstrap.eni_ips
}

output "storage_bucket" {
  value = aws_s3_bucket.loki_storage.bucket
}

output "loki_lb_dns_name" {
  value = aws_lb.loki_lb.dns_name
}

output "loki_password" {
  value     = random_string.loki_password.result
  sensitive = true
}

output "loki_username" {
  value = "admin"
}

output "loki_url" {
  value = "https://${module.domains.loki_fqdn}:${module.syslog_ports.loki_http_port}"
}
