output "create_db_script_content" {
  value     = module.om_config.create_db_script_content
  sensitive = true
}

output "concourse_template" {
  value     = module.om_config.concourse_template
  sensitive = true
}

output "director_template" {
  value     = module.om_config.director_template
  sensitive = true
}

output "clamav_addon_template" {
  value     = module.clamav_config.clamav_addon_template
  sensitive = true
}

output "clamav_mirror_template" {
  value     = module.clamav_config.clamav_mirror_template
  sensitive = true
}

output "runtime_config_template" {
  value     = module.runtime_config_config.runtime_config_template
  sensitive = true
}

output "concourse_username_and_passwords" {
  value     = module.om_config.concourse_username_and_passwords
  sensitive = true
}

