resource "aws_lb" "nlb" {
  count = 1

  name                             = var.name
  enable_cross_zone_load_balancing = true
  internal                         = var.internetless
  load_balancer_type               = "network"
  subnets                          = var.public_subnet_ids
  idle_timeout                     = 600
  tags                             = var.nlb_tag
}

variable "instance_port" {
}

variable "port" {
  type = string
}

variable "internetless" {
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "nlb_tag" {
  type = map(string)
}

variable "name" {
}

output "nlb_name" {
  value = aws_lb.nlb[0].name
}

output "nlb_arn" {
  value = aws_lb.nlb[0].arn
}

output "nlb_id" {
  value = aws_lb.nlb[0].id
}

output "dns_name" {
  value = aws_lb.nlb[0].dns_name
}

