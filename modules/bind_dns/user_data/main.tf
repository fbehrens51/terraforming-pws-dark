variable "client_cidr" {
}

variable "zone_name" {
}

variable "master_ips" {
  type = list(string)
}

variable "om_public_ip" {}
variable "control_plane_om_public_ip" {}
variable "control_plane_plane_elb_dns" {}
variable "control_plane_plane_uaa_elb_dns" {}
variable "control_plane_plane_credhub_elb_dns" {}
variable "pas_elb_dns" {}
variable "postfix_private_ip" {}
variable "fluentd_dns_name" {}
variable "grafana_elb_dns" {}


module "bind_conf_content" {
  source      = "../conf"
  client_cidr = var.client_cidr
  master_ips  = var.master_ips
  zone_name   = var.zone_name

  om_public_ip                        = var.om_public_ip
  control_plane_om_public_ip          = var.control_plane_om_public_ip
  control_plane_plane_elb_dns         = var.control_plane_plane_elb_dns
  pas_elb_dns                         = var.pas_elb_dns
  postfix_private_ip                  = var.postfix_private_ip
  fluentd_dns_name                    = var.fluentd_dns_name
  grafana_elb_dns                     = var.grafana_elb_dns
  control_plane_plane_uaa_elb_dns     = var.control_plane_plane_uaa_elb_dns
  control_plane_plane_credhub_elb_dns = var.control_plane_plane_credhub_elb_dns
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
