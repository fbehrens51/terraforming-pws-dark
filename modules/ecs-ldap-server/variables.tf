
variable "eagle-openldap-image" {

}

variable "users" {
  type = list(object({ common_name = string, ou = string, roles = list(string) }))
}
