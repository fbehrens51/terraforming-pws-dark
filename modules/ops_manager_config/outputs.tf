output "create_db_script_content" {
  value     = data.template_file.create_db.rendered
  sensitive = true
}

output "drop_db_script_content" {
  value     = data.template_file.drop_db.rendered
  sensitive = true
}

output "cf_template" {
  value     = data.template_file.cf_template.rendered
  sensitive = true
}

output "director_template" {
  value     = local.director_template
  sensitive = true
}

output "cf_tools_template" {
  value     = data.template_file.cf_tools_template.rendered
  sensitive = true
}

output "portal_template" {
  value     = data.template_file.portal_template.rendered
  sensitive = true
}