variable "root_domain" {}

locals {
  ldap_subdomain = "ldap"
  ldap_fqdn      = "${local.ldap_subdomain}.${var.root_domain}"

  splunk_subdomain = "splunk"
  splunk_fqdn      = "${local.splunk_subdomain}.${var.root_domain}"

  om_subdomain = "om"
  om_fqdn      = "${local.om_subdomain}.${var.root_domain}"

  splunk_monitor_subdomain = "splunk-monitor"
  splunk_monitor_fqdn      = "${local.splunk_monitor_subdomain}.${var.root_domain}"

  splunk_logs_subdomain = "splunk-logs"
  splunk_logs_fqdn      = "${local.splunk_logs_subdomain}.${var.root_domain}"

  control_plane_om_subdomain = "om.ci"
  control_plane_om_fqdn      = "${local.control_plane_om_subdomain}.${var.root_domain}"

  control_plane_uaa_subdomain = "uaa.ci"
  control_plane_uaa_fqdn      = "${local.control_plane_uaa_subdomain}.${var.root_domain}"

  control_plane_credhub_subdomain = "credhub.ci"
  control_plane_credhub_fqdn      = "${local.control_plane_credhub_subdomain}.${var.root_domain}"

  control_plane_plane_subdomain = "plane.ci"
  control_plane_plane_fqdn      = "${local.control_plane_plane_subdomain}.${var.root_domain}"

  system_subdomain = "run"
  system_fqdn      = "${local.system_subdomain}.${var.root_domain}"

  apps_subdomain = "cfapps"
  apps_fqdn      = "${local.apps_subdomain}.${var.root_domain}"
}

output "ldap_subdomain" {
  value = "${local.ldap_subdomain}"
}

output "ldap_fqdn" {
  value = "${local.ldap_fqdn}"
}

output "splunk_subdomain" {
  value = "${local.splunk_subdomain}"
}

output "splunk_fqdn" {
  value = "${local.splunk_fqdn}"
}

output "control_plane_om_subdomain" {
  value = "${local.control_plane_om_subdomain}"
}

output "control_plane_om_fqdn" {
  value = "${local.control_plane_om_fqdn}"
}

output "control_plane_uaa_subdomain" {
  value = "${local.control_plane_uaa_subdomain}"
}

output "control_plane_uaa_fqdn" {
  value = "${local.control_plane_uaa_fqdn}"
}

output "control_plane_plane_subdomain" {
  value = "${local.control_plane_plane_subdomain}"
}

output "control_plane_plane_fqdn" {
  value = "${local.control_plane_plane_fqdn}"
}

output "control_plane_credhub_subdomain" {
  value = "${local.control_plane_credhub_subdomain}"
}

output "control_plane_credhub_fqdn" {
  value = "${local.control_plane_credhub_fqdn}"
}

output "om_subdomain" {
  value = "${local.om_subdomain}"
}

output "om_fqdn" {
  value = "${local.om_fqdn}"
}

output "splunk_logs_subdomain" {
  value = "${local.splunk_logs_subdomain}"
}

output "splunk_logs_fqdn" {
  value = "${local.splunk_logs_fqdn}"
}

output "splunk_monitor_subdomain" {
  value = "${local.splunk_monitor_subdomain}"
}

output "splunk_monitor_fqdn" {
  value = "${local.splunk_monitor_fqdn}"
}

output "system_fqdn" {
  value = "${local.system_fqdn}"
}

output "system_subdomain" {
  value = "${local.system_subdomain}"
}

output "apps_fqdn" {
  value = "${local.apps_fqdn}"
}

output "apps_subdomain" {
  value = "${local.apps_subdomain}"
}
