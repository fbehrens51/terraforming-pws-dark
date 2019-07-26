variable "basedn" {
  type = "string"
}

variable "admin" {
  type = "string"
}

variable "password" {
  type = "string"
}

variable "users" {
  type = "list"
}

variable "root_domain" {
  type = "string"
}

variable "tls_server_cert" {
  type = "string"
}

variable "tls_server_key" {
  type = "string"
}

variable "tls_server_ca_cert" {
  type = "string"
}

variable "ssh_private_key_pem" {
  type = "string"
}

variable "ssh_host" {
  type = "string"
}

variable "instance_id" {
  type = "string"
}

variable "user_certs" {
  type = "map"
}
