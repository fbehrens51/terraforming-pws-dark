variable "users" {
  type = "list"
}

variable "domain" {
  type = "string"
}

variable "tls_server_cert" {
  type = "string"
}

variable "tls_server_key" {
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

variable "env_name" {
  type = "string"
}
