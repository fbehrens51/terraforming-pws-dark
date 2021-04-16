locals {
  om_syslog_conf = yamlencode({
    "syslog-settings" : {
      "enabled" : true,
      "address" : var.syslog_host,
      "port" : var.syslog_port,
      "transport_protocol" : "tcp",
      "tls_enabled" : true,
      "ssl_ca_certificate" : var.syslog_ca_cert,
      "permitted_peer" : var.syslog_host,
      "queue_size" : null,
      "forward_debug_logs" : false
    }
  })
  om_ssl_conf = yamlencode({
    "ssl-certificate" : {
      "certificate" : var.control_plane_star_server_cert,
      "private_key" : var.control_plane_star_server_key
    }
  })
  om_ssh_banner_conf = yamlencode({
    "banner-settings" : {
      "ssh_banner_contents" : var.custom_ssh_banner
    }
  })
  om_tokens_expiration_conf = yamlencode({
    "tokens-expiration" : {
      "access_token_expiration" : 3600,   # 1 hour
      "refresh_token_expiration" : 82800, # 23 hours
      "session_idle_timeout" : 3600       # 1 hour
    }
  })
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}

data "template_file" "control_plane_vpc_azs" {
  count = length(var.control_plane_subnet_availability_zones)

  template = <<EOF
- name: $${control_plane_subnet_availability_zone}
EOF

  vars = {
    control_plane_subnet_availability_zone = var.control_plane_subnet_availability_zones[count.index]
  }
}

data "template_file" "control_plane_subnets" {
  count = length(var.control_plane_subnet_ids)

  template = <<EOF
- availability_zone_names:
  - $${control_plane_subnet_availability_zone}
  cidr: $${control_plane_subnet_cidr}
  dns: $${control_plane_vpc_dns}
  gateway: $${control_plane_subnet_gateway}
  iaas_identifier: $${control_plane_subnet_id}
  reserved_ip_ranges: $${control_plane_subnet_reserved_ips}
EOF

  vars = {
    control_plane_subnet_id                = var.control_plane_subnet_ids[count.index]
    control_plane_subnet_availability_zone = var.control_plane_subnet_availability_zones[count.index]
    control_plane_subnet_cidr              = var.control_plane_subnet_cidrs[count.index]
    control_plane_subnet_reserved_ips      = "${cidrhost(var.control_plane_subnet_cidrs[count.index], 1)}-${cidrhost(var.control_plane_subnet_cidrs[count.index], 4)},${var.control_plane_additional_reserved_ips[var.control_plane_subnet_ids[count.index]]}"
    control_plane_subnet_gateway           = var.control_plane_subnet_gateways[count.index]
    control_plane_vpc_dns                  = var.control_plane_vpc_dns
  }
}

locals {
  director_template = templatefile("${path.module}/director_template.tpl", {
    scale                                       = var.scale["p-bosh"]
    ec2_endpoint                                = var.ec2_endpoint
    elb_endpoint                                = var.elb_endpoint
    rds_host                                    = var.mysql_host
    rds_port                                    = var.mysql_port
    rds_db_name                                 = var.mysql_db_name
    rds_username                                = var.mysql_username
    rds_password                                = var.mysql_password
    rds_ca_cert                                 = var.mysql_ca_cert
    singleton_availability_zone                 = var.singleton_availability_zone
    custom_ssh_banner                           = var.custom_ssh_banner
    smtp_domain                                 = var.smtp_domain
    smtp_enabled                                = var.smtp_enabled
    smtp_from                                   = var.smtp_from
    smtp_host                                   = var.smtp_host
    smtp_port                                   = var.smtp_port
    smtp_recipients                             = var.smtp_recipients
    smtp_user                                   = var.smtp_user
    smtp_password                               = var.smtp_password
    smtp_tls                                    = var.smtp_tls
    env_name                                    = var.env_name
    ntp_servers                                 = join(",", var.ntp_servers)
    iaas_configuration_endpoints_ca_cert        = var.iaas_configuration_endpoints_ca_cert
    iaas_configuration_iam_instance_profile     = var.iaas_configuration_iam_instance_profile
    iaas_configuration_ssh_key_pair_name        = var.ops_manager_ssh_public_key_name
    iaas_configuration_region                   = var.region
    iaas_configuration_security_group           = var.vms_security_group_id
    iaas_configuration_ssh_private_key          = chomp(var.ops_manager_ssh_private_key)
    security_configuration_trusted_certificates = chomp(var.security_configuration_trusted_certificates)
    kms_key_arn                                 = var.volume_encryption_kms_key_arn
    concourse_worker_role_name                  = var.concourse_worker_role_name
    concourse_lb_security_group_id              = "[${join(",", var.concourse_lb_security_group_id)}]"
    control_plane_subnets                       = indent(4, chomp(join("", data.template_file.control_plane_subnets.*.rendered)))
    control_plane_vpc_azs                       = indent(2, chomp(join("", data.template_file.control_plane_vpc_azs.*.rendered)))
    syslog_host                                 = var.syslog_host
    syslog_port                                 = var.syslog_port
    syslog_ca_cert                              = var.syslog_ca_cert
    blobstore_instance_profile                  = var.blobstore_instance_profile,
    director_blobstore_bucket                   = var.director_blobstore_bucket,
    director_blobstore_s3_endpoint              = "https://${var.s3_endpoint}",
    director_blobstore_location                 = var.director_blobstore_location, // s3 or local
  })
}

module "domains" {
  source = "../domains"

  root_domain = var.root_domain
}

data "template_file" "create_db" {
  template = file("${path.module}/create_db.tpl")

  vars = {
    postgres_host             = var.postgres_host
    postgres_port             = var.postgres_port
    postgres_username         = var.postgres_username
    postgres_password         = var.postgres_password
    postgres_db_name          = var.postgres_db_name
    postgres_credhub_db_name  = var.postgres_credhub_db_name
    postgres_credhub_username = var.postgres_credhub_username
    postgres_credhub_password = var.postgres_credhub_password
    postgres_uaa_db_name      = var.postgres_uaa_db_name
    postgres_uaa_username     = var.postgres_uaa_username
    postgres_uaa_password     = var.postgres_uaa_password
    mysql_host                = var.mysql_host
    mysql_port                = var.mysql_port
    mysql_username            = var.mysql_username
    mysql_password            = var.mysql_password
    mysql_db_name             = var.mysql_db_name
  }
}

data "template_file" "admin_users" {
  count = length(var.admin_users)

  template = <<EOF
- username: ${var.admin_users[count.index]}
EOF
}

locals {
  concourse_template = templatefile("${path.module}/concourse_template.tpl", {
    scale                       = var.scale["pws-dark-concourse-tile"]
    singleton_availability_zone = var.singleton_availability_zone
    control_plane_vpc_azs = indent(
      4,
      chomp(join("", data.template_file.control_plane_vpc_azs.*.rendered)),
    )
    web_tg_names              = "[${join(",", formatlist("alb:%s", var.web_tg_names))}]"
    credhub_tg_names          = "[${join(",", formatlist("alb:%s", var.credhub_tg_names))}]"
    uaa_elb_names             = "[${join(",", var.uaa_elb_names)}]"
    credhub_elb_names         = "[${join(",", var.credhub_elb_names)}]"
    plane_endpoint            = module.domains.control_plane_plane_fqdn
    uaa_endpoint              = "${module.domains.control_plane_uaa_fqdn}:8443"
    concourse_cert_pem        = var.concourse_cert_pem
    concourse_private_key_pem = var.concourse_private_key_pem
    ca_certificate            = var.ca_certificate
    uaa_cert_pem              = var.uaa_cert_pem
    uaa_private_key_pem       = var.uaa_private_key_pem
    syslog_host               = var.syslog_host
    syslog_port               = var.syslog_port
    syslog_ca_cert            = var.syslog_ca_cert
    postgres_host             = var.postgres_host
    postgres_port             = var.postgres_port
    postgres_uaa_db_name      = var.postgres_uaa_db_name
    postgres_uaa_username     = var.postgres_uaa_username
    postgres_uaa_password     = var.postgres_uaa_password
    postgres_db_name          = var.postgres_db_name
    postgres_username         = var.postgres_username
    postgres_password         = var.postgres_password
    postgres_ca_cert          = var.postgres_ca_cert
    admin_users               = join("", data.template_file.admin_users.*.rendered)
    credhub_cert_pem          = var.credhub_cert_pem
    credhub_private_key_pem   = var.credhub_private_key_pem
    postgres_credhub_db_name  = var.postgres_credhub_db_name
    postgres_credhub_username = var.postgres_credhub_username
    postgres_credhub_password = var.postgres_credhub_password
    credhub_endpoint          = "${module.domains.control_plane_credhub_fqdn}:8844"
  })
}

resource "aws_s3_bucket_object" "om_create_db_config" {
  bucket  = var.secrets_bucket_name
  key     = var.om_create_db_config
  content = data.template_file.create_db.rendered
}

resource "aws_s3_bucket_object" "om_ssh_banner_config" {
  bucket  = var.secrets_bucket_name
  key     = var.om_ssh_banner_config
  content = local.om_ssh_banner_conf
}

resource "aws_s3_bucket_object" "om_ssl_config" {
  bucket  = var.secrets_bucket_name
  key     = var.om_ssl_config
  content = local.om_ssl_conf
}

resource "aws_s3_bucket_object" "om_tokens_expiration_config" {
  bucket  = var.secrets_bucket_name
  key     = var.om_tokens_expiration_config
  content = local.om_tokens_expiration_conf
}

resource "aws_s3_bucket_object" "om_syslog_config" {
  bucket  = var.secrets_bucket_name
  key     = var.om_syslog_config
  content = local.om_syslog_conf
}

resource "aws_s3_bucket_object" "director_template" {
  bucket  = var.secrets_bucket_name
  key     = var.director_config
  content = local.director_template
}

resource "aws_s3_bucket_object" "concourse_template" {
  bucket  = var.secrets_bucket_name
  key     = var.concourse_config
  content = local.concourse_template
}
