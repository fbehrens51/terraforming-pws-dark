output "platform_automation_engine_template" {
  value = "${module.om_config.platform_automation_engine_template}"
}

output "director_template" {
  value = "${module.om_config.director_template}"
}

output "download_platform_automation_engine_config" {
  value = "${module.om_config.download_platform_automation_engine_config}"
}

output "download_pws_dark_iam_s3_resource_config" {
  value = "${module.om_config.download_pws_dark_iam_s3_resource_config}"
}
