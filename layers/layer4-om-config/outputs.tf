output "create_db_script_content" {
  value = "${module.om_config.create_db_script_content}"
}

output "drop_db_script_content" {
  value = "${module.om_config.drop_db_script_content}"
}

output "cf_template" {
  value = "${module.om_config.cf_template}"
}

output "director_template" {
  value = "${module.om_config.director_template}"
}

output "portal_template" {
  value = "${module.om_config.portal_template}"
}