variable "client_cidr" {
}

variable "zone_name" {
}

variable "master_ips" {
  type = list(string)
}

variable "shared_alb" {}
variable "control_plane_plane_elb_dns" {}
variable "control_plane_plane_uaa_elb_dns" {}
variable "pas_elb_dns" {}
variable "postfix_private_ip" {}
variable "splunk_logs_private_ip" {}
variable "fluentd_private_ip" {}


module "bind_conf_content" {
  source      = "../conf"
  client_cidr = var.client_cidr
  master_ips  = var.master_ips
  zone_name   = var.zone_name

  shared_alb                      = var.shared_alb
  control_plane_plane_elb_dns     = var.control_plane_plane_elb_dns
  pas_elb_dns                     = var.pas_elb_dns
  postfix_private_ip              = var.postfix_private_ip
  splunk_logs_private_ip          = var.splunk_logs_private_ip
  fluentd_private_ip              = var.fluentd_private_ip
  control_plane_plane_uaa_elb_dns = var.control_plane_plane_uaa_elb_dns
}

data "template_file" "user_data" {
  template = file("${path.module}/user_data.tpl")

  vars = {
    named_conf_content = base64encode(module.bind_conf_content.named_conf_content)
    zone_content       = base64encode(module.bind_conf_content.zone_content)
    zone_file_name     = "db.${var.zone_name}"
  }
}

output "user_data" {
  value     = data.template_file.user_data.rendered
  sensitive = true
}

