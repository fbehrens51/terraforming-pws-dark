variable "basedn" {
  type = string
}

variable "admin" {
  type = string
}

variable "password" {
  type = string
}

variable "users" {
  type = list(object({ name = string, username = string, roles = string }))
}

variable "root_domain" {
  type = string
}

variable "tls_server_cert" {
  type = string
}

variable "tls_server_key" {
  type = string
}

variable "tls_server_ca_cert" {
  type = string
}

variable "bot_user" {
  default = "bot"
}

variable "bot_key_pem" {
  type = string
}

variable "bastion_host" {
  type    = string
  default = null
}

variable "instance_id" {
  type = string
}

variable "private_ip" {
  default = null
  type    = string
}

variable "user_certs" {
  type = map(string)
}

