terraform {
  backend "s3" {
  }
}

module "providers" {
  source = "../../modules/dark_providers"
}

provider "aws" {
}

locals {
  cert_bucket                                      = "${replace(var.env_name, " ", "-")}-secrets"
  cap_root_ca_cert_s3_path                         = "cap_root_ca_cert.pem"
  root_ca_cert_s3_path                             = "root_ca_cert.pem"
  router_trusted_ca_certs_s3_path                  = "router_trusted_ca_certs.pem"
  trusted_ca_certs_s3_path                         = "trusted_ca_certs.pem"
  additional_trusted_ca_certs_s3_path              = "additional_trusted_ca_certs.pem"
  rds_ca_cert_s3_path                              = "rds_ca_cert.pem"
  smtp_relay_password_s3_path                      = "smtp_relay_password.pem"
  smtp_relay_ca_cert_s3_path                       = "smtp_relay_ca_cert.pem"
  grafana_server_cert_s3_path                      = "grafana_server_cert.pem"
  grafana_server_key_s3_path                       = "grafana_server_key.pem"
  router_server_cert_s3_path                       = "router_server_cert.pem"
  router_server_key_s3_path                        = "router_server_key.pem"
  uaa_server_cert_s3_path                          = "uaa_server_cert.pem"
  uaa_server_key_s3_path                           = "uaa_server_key.pem"
  ldap_client_cert_s3_path                         = "ldap_client_cert.pem"
  ldap_client_key_s3_path                          = "ldap_client_key.pem"
  om_server_cert_s3_path                           = "om_server_cert.pem"
  om_server_key_s3_path                            = "om_server_key.pem"
  control_plane_star_server_cert_s3_path           = "control_plane_star_server_cert.pem"
  control_plane_star_server_key_s3_path            = "control_plane_star_server_key.pem"
  smtp_server_cert_s3_path                         = "smtp_server_cert.pem"
  smtp_server_key_s3_path                          = "smtp_server_key.pem"
  fluentd_server_cert_s3_path                      = "fluentd_server_cert.pem"
  fluentd_server_key_s3_path                       = "fluentd_server_key.pem"
  portal_smoke_test_cert_s3_path                   = "portal_smoke_test_cert.pem"
  portal_smoke_test_key_s3_path                    = "portal_smoke_test_key.pem"
  ldap_password_s3_path                            = "ldap_password.txt"
  portal_end_to_end_test_user_cert_pem_path        = "portal_end_to_end_test_user_cert.pem"
  portal_end_to_end_test_user_private_key_pem_path = "portal_end_to_end_test_user_key.pem"
  vanity_server_cert_s3_path                       = "vanity_cert.pem"
  vanity_server_key_s3_path                        = "vanity_key.pem"

  basedn = "dc=${join(",dc=", split(".", var.root_domain))}"
  admin  = "cn=admin,dc=${join(",dc=", split(".", var.root_domain))}"
}

resource "random_string" "ldap_password" {
  length  = "16"
  special = false
}

resource "aws_eip" "ldap_eip" {
  vpc = true
}

module "domains" {
  source = "../../modules/domains"

  root_domain = var.root_domain
}

module "paperwork" {
  source                    = "./modules/paperwork"
  bucket_role_name          = var.pas_bucket_role_name
  worker_role_name          = var.platform_automation_engine_worker_role_name
  director_role_name        = var.director_role_name
  fluentd_role_name         = var.fluentd_role_name
  instance_tagger_role_name = var.instance_tagger_role_name
  tsdb_role_name            = var.tsdb_role_name
  ldap_eip                  = aws_eip.ldap_eip.public_ip

  env_name    = var.env_name
  root_domain = var.root_domain
  users       = var.users
}

data "aws_caller_identity" "current_user" {
}

resource "aws_s3_bucket" "certs" {
  bucket_prefix = local.cert_bucket
  acl           = "private"
  force_destroy = var.force_destroy_buckets

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

data "template_file" "paperwork_variables" {
  template = file("${path.module}/paperwork.tfvars.tpl")

  vars = {
    root_domain                                 = var.root_domain
    apps_domain                                 = module.domains.apps_fqdn
    system_domain                               = module.domains.system_fqdn
    bucket_role_name                            = var.pas_bucket_role_name
    platform_automation_engine_worker_role_name = var.platform_automation_engine_worker_role_name
    tsdb_role_name                              = var.tsdb_role_name
    fluentd_role_name                           = var.fluentd_role_name
    instance_tagger_role_name                   = var.instance_tagger_role_name
    director_role_name                          = var.director_role_name
    sjb_role_name                               = var.director_role_name
    cp_vpc_id                                   = module.paperwork.cp_vpc_id
    es_vpc_id                                   = module.paperwork.es_vpc_id
    bastion_vpc_id                              = module.paperwork.bastion_vpc_id
    pas_vpc_id                                  = module.paperwork.pas_vpc_id
    iso_vpc_id                                  = module.paperwork.isolation_segment_vpc_1_id
    pas_vpc_dns                                 = module.paperwork.pas_vpc_dns
    control_plane_vpc_dns                       = module.paperwork.control_plane_vpc_dns
    ldap_basedn                                 = local.basedn
    ldap_dn                                     = local.admin
    ldap_host                                   = aws_eip.ldap_eip.public_ip
    ldap_port                                   = "636"
    ldap_role_attr                              = "role"
    ldap_password_s3_path                       = local.ldap_password_s3_path
    cert_bucket                                 = aws_s3_bucket.certs.bucket
    cap_root_ca_s3_path                         = local.cap_root_ca_cert_s3_path
    root_ca_cert_s3_path                        = local.root_ca_cert_s3_path
    router_trusted_ca_certs_s3_path             = local.router_trusted_ca_certs_s3_path
    trusted_ca_certs_s3_path                    = local.trusted_ca_certs_s3_path
    additional_trusted_ca_certs_s3_path         = local.additional_trusted_ca_certs_s3_path
    rds_ca_cert_s3_path                         = local.rds_ca_cert_s3_path
    smtp_relay_ca_cert_s3_path                  = local.smtp_relay_ca_cert_s3_path
    smtp_relay_password_s3_path                 = local.smtp_relay_password_s3_path
    grafana_server_cert_s3_path                 = local.grafana_server_cert_s3_path
    grafana_server_key_s3_path                  = local.grafana_server_key_s3_path
    router_server_cert_s3_path                  = local.router_server_cert_s3_path
    router_server_key_s3_path                   = local.router_server_key_s3_path
    uaa_server_cert_s3_path                     = local.uaa_server_cert_s3_path
    uaa_server_key_s3_path                      = local.uaa_server_key_s3_path
    ldap_client_cert_s3_path                    = local.ldap_client_cert_s3_path
    ldap_client_key_s3_path                     = local.ldap_client_key_s3_path
    om_server_cert_s3_path                      = local.om_server_cert_s3_path
    om_server_key_s3_path                       = local.om_server_key_s3_path
    control_plane_star_server_cert_s3_path      = local.control_plane_star_server_cert_s3_path
    control_plane_star_server_key_s3_path       = local.control_plane_star_server_key_s3_path
    smtp_server_cert_s3_path                    = local.smtp_server_cert_s3_path
    smtp_server_key_s3_path                     = local.smtp_server_key_s3_path
    fluentd_server_cert_s3_path                 = local.fluentd_server_cert_s3_path
    fluentd_server_key_s3_path                  = local.fluentd_server_key_s3_path
    portal_smoke_test_cert_s3_path              = local.portal_smoke_test_cert_s3_path
    portal_smoke_test_key_s3_path               = local.portal_smoke_test_key_s3_path
    vanity_server_cert_s3_path                  = local.vanity_server_cert_s3_path
    vanity_server_key_s3_path                   = local.vanity_server_key_s3_path
  }
}

data "template_file" "keymanager_variables" {
  template = file("${path.module}/keymanager.tfvars.tpl")
  vars = {
    pas_bucket_role_arn = module.paperwork.pas_bucket_role_arn
    director_role_arn   = module.paperwork.director_role_arn
  }
}

variable "force_destroy_buckets" {
  type    = bool
  default = false
}

variable "paperwork_variable_output_path" {
  type = string
}

variable "keymanager_variable_output_path" {
  type = string
}

variable "bootstrap_isolation_segment_vpc_variable_output_path" {
  type = string
}

variable "platform_automation_engine_worker_role_name" {
  type = string
}

variable "pas_bucket_role_name" {
  type = string
}

variable "fluentd_role_name" {
  type = string
}

variable "instance_tagger_role_name" {
  type = string
}

variable "director_role_name" {
  type = string
}

variable "tsdb_role_name" {
}

variable "env_name" {
  type = string
}

variable "root_domain" {
  type = string
}

variable "users" {
  type = list(object({
    name     = string,
    username = string,
    ou       = string,
    roles    = string
  }))
}

resource "aws_s3_bucket_object" "cap_root_ca_cert" {
  key          = local.cap_root_ca_cert_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content      = file("${path.module}/combine_cert.pem")
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "router_trusted_ca_certs" {
  key          = local.router_trusted_ca_certs_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content      = module.paperwork.router_trusted_ca_certs
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "root_ca_cert" {
  key          = local.root_ca_cert_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content      = module.paperwork.root_ca_cert
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "trusted_ca_certs" {
  key          = local.trusted_ca_certs_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content      = module.paperwork.trusted_ca_certs
  content_type = "text/plain"
}

module "download-ca-certs" {
  source = "../../modules/download_certs"

  hosts = var.additional_trusted_ca_cert_hosts
}

resource "aws_s3_bucket_object" "additional_trusted_ca_certs" {
  key          = local.additional_trusted_ca_certs_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content      = module.download-ca-certs.ca_certs
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "rds_ca_cert" {
  key          = local.rds_ca_cert_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content      = var.rds_ca_cert_pem
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "smtp_relay_ca_cert" {
  key          = local.smtp_relay_ca_cert_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content      = var.smtp_relay_ca_cert_pem
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "smtp_relay_password" {
  key          = local.smtp_relay_password_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content      = var.smtp_relay_password
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "grafana_server_cert" {
  key          = local.grafana_server_cert_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content_type = "text/plain"
  content      = module.paperwork.grafana_server_cert
}

resource "aws_s3_bucket_object" "grafana_server_key" {
  key          = local.grafana_server_key_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content      = module.paperwork.grafana_server_key
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "router_server_cert" {
  key          = local.router_server_cert_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content_type = "text/plain"
  content      = module.paperwork.router_server_cert
}

resource "aws_s3_bucket_object" "router_server_key" {
  key          = local.router_server_key_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content      = module.paperwork.router_server_key
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "uaa_server_cert" {
  key          = local.uaa_server_cert_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content      = module.paperwork.uaa_server_cert
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "uaa_server_key" {
  key          = local.uaa_server_key_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content      = module.paperwork.uaa_server_key
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "om_server_cert" {
  key          = local.om_server_cert_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content      = module.paperwork.om_server_cert
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "om_server_key" {
  key          = local.om_server_key_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content_type = "text/plain"
  content      = module.paperwork.om_server_key
}

resource "aws_s3_bucket_object" "control_plane_star_server_cert" {
  key          = local.control_plane_star_server_cert_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content      = module.paperwork.control_plane_star_server_cert
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "control_plane_star_server_key" {
  key          = local.control_plane_star_server_key_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content_type = "text/plain"
  content      = module.paperwork.control_plane_star_server_key
}

resource "aws_s3_bucket_object" "fluentd_server_cert" {
  key          = local.fluentd_server_cert_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content      = module.paperwork.fluentd_server_cert
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "fluentd_server_key" {
  key          = local.fluentd_server_key_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content_type = "text/plain"
  content      = module.paperwork.fluentd_server_key
}

resource "aws_s3_bucket_object" "smtp_server_cert" {
  key          = local.smtp_server_cert_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content      = module.paperwork.smtp_server_cert
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "smtp_server_key" {
  key          = local.smtp_server_key_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content_type = "text/plain"
  content      = module.paperwork.smtp_server_key
}

resource "aws_s3_bucket_object" "ldap_client_cert" {
  key          = local.ldap_client_cert_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content      = module.paperwork.ldap_client_cert
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "ldap_client_key" {
  key          = local.ldap_client_key_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content_type = "text/plain"
  content      = module.paperwork.ldap_client_key
}

resource "aws_s3_bucket_object" "vanity_server_cert" {
  key          = local.vanity_server_cert_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content      = module.paperwork.vanity_server_cert
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "vanity_server_key" {
  key          = local.vanity_server_key_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content_type = "text/plain"
  content      = module.paperwork.vanity_server_key
}

resource "aws_s3_bucket_object" "portal_smoke_test_cert" {
  key    = local.portal_smoke_test_cert_s3_path
  bucket = aws_s3_bucket.certs.bucket
  content = element(
    module.paperwork.user_certs,
    index(module.paperwork.usernames, "smoke"),
  )
  content_type = "text/plain"
}

resource "aws_s3_bucket_object" "portal_smoke_test_key" {
  key          = local.portal_smoke_test_key_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content_type = "text/plain"
  content = element(
    module.paperwork.user_private_keys,
    index(module.paperwork.usernames, "smoke"),
  )
}

resource "aws_s3_bucket_object" "ldap_password" {
  key          = local.ldap_password_s3_path
  bucket       = aws_s3_bucket.certs.bucket
  content_type = "text/plain"
  content      = random_string.ldap_password.result
}

resource "local_file" "paperwork_variables" {
  filename = var.paperwork_variable_output_path
  content  = data.template_file.paperwork_variables.rendered
}

resource "local_file" "keymanager_variables" {
  filename = var.keymanager_variable_output_path
  content  = data.template_file.keymanager_variables.rendered
}

resource "local_file" "bootstrap_isolation_segment_vpc_variables" {
  filename = var.bootstrap_isolation_segment_vpc_variable_output_path
  content  = <<EOF
vpc_id = "${module.paperwork.isolation_segment_vpc_1_id}"
EOF
}

# The following outputs are used by the portal test suite and are not needed by the paperwork layer
output "portal_end_to_end_test_user_cert_pem" {
  value = module.paperwork.portal_end_to_end_test_user_cert_pem
}

output "portal_end_to_end_test_user_private_key_pem" {
  value     = module.paperwork.portal_end_to_end_test_user_private_key_pem
  sensitive = true
}

output "portal_end_to_end_test_application_cert_pem" {
  value = module.paperwork.portal_end_to_end_test_application_cert_pem
}

output "portal_end_to_end_test_application_private_key_pem" {
  value     = module.paperwork.portal_end_to_end_test_application_private_key_pem
  sensitive = true
}

output "portal_end_to_end_test_application_cert_b_pem" {
  value = module.paperwork.portal_end_to_end_test_application_cert_b_pem
}

output "portal_end_to_end_test_application_private_key_b_pem" {
  value     = module.paperwork.portal_end_to_end_test_application_private_key_b_pem
  sensitive = true
}


# The following outputs are used by the ldap layer but are not needed by the
# paperwork layer

output "ldap_server_cert" {
  value = module.paperwork.ldap_server_cert
}

output "ldap_server_key" {
  value     = module.paperwork.ldap_server_key
  sensitive = true
}

output "usernames" {
  value     = module.paperwork.usernames
  sensitive = true
}

output "user_private_keys" {
  value     = module.paperwork.user_private_keys
  sensitive = true
}

output "user_certs" {
  value     = module.paperwork.user_certs
  sensitive = true
}

variable "rds_ca_cert_pem" {
  type = string
}

variable "smtp_relay_ca_cert_pem" {
  type = string
}

variable "smtp_relay_password" {
  type = string
}

variable "additional_trusted_ca_cert_hosts" {
  type = list(string)
}
