output "create_db_script_content" {
  value = "${data.template_file.create_db.rendered}"
  sensitive = true
}

output "drop_db_script_content" {
  value = "${data.template_file.drop_db.rendered}"
  sensitive = true
}

output "cf_template" {
  value = "${data.template_file.cf_template.rendered}"
  sensitive = true
}

output "director_template" {
  value = "${data.template_file.director_template.rendered}"
  sensitive = true
}

output "portal_template" {
  value = "${data.template_file.portal_template.rendered}"
  sensitive = true
}

output "download_pas_config" {
  value = "${data.template_file.download_pas_config.rendered}"
  sensitive = true
}

output "download_splunk_config" {
  value = "${data.template_file.download_splunk_config.rendered}"
  sensitive = true
}

output "download_portal_config" {
  value = "${data.template_file.download_portal_config.rendered}"
  sensitive = true
}

output "download_healthwatch_config" {
  value = "${data.template_file.download_healthwatch_config.rendered}"
  sensitive = true
}

output "download_clamav_mirror_config" {
  value = "${data.template_file.download_clamav_mirror_config.rendered}"
  sensitive = true
}

output "download_clamav_addon_config" {
  value = "${data.template_file.download_clamav_addon_config.rendered}"
  sensitive = true
}
