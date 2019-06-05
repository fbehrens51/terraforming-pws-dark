variable "om_eip" {}

variable "vm_count" {}

variable "private" {}

variable "env_name" {}

variable "subnet_id" {}

variable "vpc_id" {}

variable "dns_suffix" {}

variable "use_route53" {}

variable "zone_id" {}

variable "bucket_suffix" {}

variable "tags" {
  type = "map"
}

variable "ingress_rules" {
  type = "list"
}

variable "ops_manager_role_name" {}
