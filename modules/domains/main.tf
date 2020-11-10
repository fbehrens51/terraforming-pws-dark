variable "root_domain" {
}

locals {
  smtp_subdomain = "smtp"
  smtp_fqdn      = "${local.smtp_subdomain}.${var.root_domain}"

  om_subdomain = "om"
  om_fqdn      = "${local.om_subdomain}.${var.root_domain}"

  grafana_subdomain = "grafana"
  grafana_fqdn      = "${local.grafana_subdomain}.${var.root_domain}"

  fluentd_subdomain = "fluentd"
  fluentd_fqdn      = "${local.fluentd_subdomain}.${var.root_domain}"

  control_plane_om_subdomain = "om.ci"
  control_plane_om_fqdn      = "${local.control_plane_om_subdomain}.${var.root_domain}"

  control_plane_uaa_subdomain = "uaa.ci"
  control_plane_uaa_fqdn      = "${local.control_plane_uaa_subdomain}.${var.root_domain}"

  control_plane_plane_subdomain = "plane.ci"
  control_plane_plane_fqdn      = "${local.control_plane_plane_subdomain}.${var.root_domain}"

  control_plane_star_subdomain = "*.ci"
  control_plane_star_fqdn      = "${local.control_plane_star_subdomain}.${var.root_domain}"

  system_subdomain = "run"
  system_fqdn      = "${local.system_subdomain}.${var.root_domain}"

  apps_subdomain = "cfapps"
  apps_fqdn      = "${local.apps_subdomain}.${var.root_domain}"

  apps_manager_subdomain = "apps"
  apps_manager_fqdn      = "${local.apps_manager_subdomain}.${local.system_fqdn}"
}

output "smtp_subdomain" {
  value = local.smtp_subdomain
}

output "smtp_fqdn" {
  value = local.smtp_fqdn
}

output "control_plane_om_subdomain" {
  value = local.control_plane_om_subdomain
}

output "control_plane_om_fqdn" {
  value = local.control_plane_om_fqdn
}

output "control_plane_plane_subdomain" {
  value = local.control_plane_plane_subdomain
}

output "control_plane_plane_fqdn" {
  value = local.control_plane_plane_fqdn
}

output "control_plane_uaa_subdomain" {
  value = local.control_plane_uaa_subdomain
}

output "control_plane_uaa_fqdn" {
  value = local.control_plane_uaa_fqdn
}

output "control_plane_star_subdomain" {
  value = local.control_plane_star_subdomain
}

output "control_plane_star_fqdn" {
  value = local.control_plane_star_fqdn
}

output "grafana_subdomain" {
  value = local.grafana_subdomain
}

output "grafana_fqdn" {
  value = local.grafana_fqdn
}

output "om_subdomain" {
  value = local.om_subdomain
}

output "om_fqdn" {
  value = local.om_fqdn
}

output "fluentd_subdomain" {
  value = local.fluentd_subdomain
}

output "fluentd_fqdn" {
  value = local.fluentd_fqdn
}

output "system_fqdn" {
  value = local.system_fqdn
}

output "system_subdomain" {
  value = local.system_subdomain
}

output "apps_fqdn" {
  value = local.apps_fqdn
}

output "apps_subdomain" {
  value = local.apps_subdomain
}

output "apps_manager_fqdn" {
  value = local.apps_manager_fqdn
}

output "apps_manager_subdomain" {
  value = local.apps_manager_subdomain
}

