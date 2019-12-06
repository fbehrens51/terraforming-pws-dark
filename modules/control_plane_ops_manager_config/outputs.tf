output "create_db_script_content" {
  value     = "${data.template_file.create_db.rendered}"
  sensitive = true
}

output "concourse_template" {
  value = "${data.template_file.concourse_template.rendered}"
}

output "director_template" {
  value = "${data.template_file.director_template.rendered}"
}

output "download_concourse_config" {
  value = "${data.template_file.download_concourse_config.rendered}"
}

output "concourse_username_and_passwords" {
  value     = "${zipmap(var.concourse_users, random_string.user_passwords.*.result)}"
  sensitive = true
}

output "download_compliance_scanner_config" {
  value     = "${data.template_file.download_compliance_scanner_config.rendered}"
  sensitive = true
}
