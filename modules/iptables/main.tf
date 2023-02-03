variable "control_plane_subnet_cidrs" {
}

variable "nat_log_new_connections" {
  type    = bool
  default = false
}

variable "nat" {
  type    = bool
  default = false
}

variable "personality_rules" {
  type    = list(string)
  default = []
}

variable "internet_only_rules" {
  type    = list(string)
  default = []
}

output "iptables_user_data" {
  sensitive = true
  value = templatefile("${path.module}/user_data.tpl", {
    control_plane_subnet_cidrs = var.control_plane_subnet_cidrs,
    nat                        = var.nat,
    nat_log_new_connections    = var.nat_log_new_connections,
    personality_rules          = var.personality_rules,
    internet_only_rules        = var.internet_only_rules,
  })
}
