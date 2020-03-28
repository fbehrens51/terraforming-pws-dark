output "concourse_username_and_passwords" {
  value     = zipmap(var.concourse_users, random_string.user_passwords.*.result)
  sensitive = true
}
