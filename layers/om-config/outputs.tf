output "create_db_script_content" {
  value = "${module.om_config.create_db_script_content}"
  sensitive = true
}

output "drop_db_script_content" {
  value = "${module.om_config.drop_db_script_content}"
  sensitive = true
}

output "cf_template" {
  value = "${module.om_config.cf_template}"
  sensitive = true
}

output "director_template" {
  value = "${module.om_config.director_template}"
  sensitive = true
}

output "portal_template" {
  value = "${module.om_config.portal_template}"
  sensitive = true
}

output "download_pas_config" {
  value = "${module.om_config.download_pas_config}"
  sensitive = true
}

output "download_portal_config" {
  value = "${module.om_config.download_portal_config}"
  sensitive = true
}

output "download_splunk_config" {
  value = "${module.om_config.download_splunk_config}"
  sensitive = true
}

output "download_healthwatch_config" {
  value = "${module.om_config.download_healthwatch_config}"
  sensitive = true
}

output "download_clamav_addon_config" {
  value = "${module.om_config.download_clamav_addon_config}"
  sensitive = true
}

output "download_clamav_mirror_config" {
  value = "${module.om_config.download_clamav_mirror_config}"
  sensitive = true
}
