variable "control_plane_subnet_cidrs" {
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
    personality_rules          = var.personality_rules,
    internet_only_rules        = var.internet_only_rules,
  })
}
