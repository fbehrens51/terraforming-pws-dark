output "platform_automation_engine_template" {
  value = "${data.template_file.platform_automation_engine_template.rendered}"
}

output "director_template" {
  value = "${data.template_file.director_template.rendered}"
}

output "download_platform_automation_engine_config" {
  value = "${data.template_file.download_platform_automation_engine_config.rendered}"
}
