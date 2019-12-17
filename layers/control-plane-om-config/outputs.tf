output "create_db_script_content" {
  value     = "${module.om_config.create_db_script_content}"
  sensitive = true
}

output "concourse_template" {
  value     = "${module.om_config.concourse_template}"
  sensitive = true
}

output "director_template" {
  value     = "${module.om_config.director_template}"
  sensitive = true
}

output "download_concourse_config" {
  value     = "${module.om_config.download_concourse_config}"
  sensitive = true
}

output "clamav_addon_template" {
  value     = "${module.clamav_config.clamav_addon_template}"
  sensitive = true
}

output "clamav_mirror_template" {
  value     = "${module.clamav_config.clamav_mirror_template}"
  sensitive = true
}

output "clamav_release_public_bucket_key" {
  value = "${var.clamav_release_public_bucket_key}"
}

output "download_clamav_addon_config" {
  value     = "${module.clamav_config.download_clamav_addon_config}"
  sensitive = true
}

output "download_clamav_mirror_config" {
  value     = "${module.clamav_config.download_clamav_mirror_config}"
  sensitive = true
}

output "download_compliance_scanner_config" {
  value     = "${module.om_config.download_compliance_scanner_config}"
  sensitive = true
}

output "download_runtime_config_config" {
  value     = "${module.runtime_config_config.download_runtime_config_config}"
  sensitive = true
}

output "runtime_config_template" {
  value     = "${module.runtime_config_config.runtime_config_template}"
  sensitive = true
}

output "concourse_username_and_passwords" {
  value     = "${module.om_config.concourse_username_and_passwords}"
  sensitive = true
}
