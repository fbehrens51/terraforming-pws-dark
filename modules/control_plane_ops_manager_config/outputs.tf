output "create_db_script_content" {
  value     = data.template_file.create_db.rendered
  sensitive = true
}

output "concourse_template" {
  value = data.template_file.concourse_template.rendered
}

output "director_template" {
  value = data.template_file.director_template.rendered
}

output "concourse_username_and_passwords" {
  value     = zipmap(var.concourse_users, random_string.user_passwords.*.result)
  sensitive = true
}
