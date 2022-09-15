variable "vpc_id" {
}

variable "tags" {
  type = map(string)
}

variable "env_name" {
}

variable "short_name" {
}

variable "internetless" {
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "egress_cidrs" {
  type = list(string)
}

variable "idle_timeout" {
  type        = number
  default     = 600
  description = "idle timeout in seconds for the elb"
}

variable "health_check" {
  default = ""
}

variable "proxy_pass" {
  type    = bool
  default = false
}

variable "listener_to_instance_ports" {
  type = list(object({
    port                = string
    instance_port       = string
    enable_proxy_policy = bool
  }))
}
