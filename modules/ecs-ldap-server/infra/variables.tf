
variable "users" {
  type = map(object({ common_name = string, ou = string, roles = list(string) }))
}
