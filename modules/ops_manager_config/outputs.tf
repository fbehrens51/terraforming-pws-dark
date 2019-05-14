
output "create_db_script_content" {
  value="${data.template_file.create_db.rendered}"
}

output "drop_db_script_content" {
  value="${data.template_file.drop_db.rendered}"
}

output "cf_template" {
  value="${data.template_file.cf_template.rendered}"
}

output "director_template" {
  value="${data.template_file.director_template.rendered}"
}

output "portal_template" {
  value="${data.template_file.portal_template.rendered}"
}
