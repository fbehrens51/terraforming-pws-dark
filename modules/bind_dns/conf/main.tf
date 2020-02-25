variable "client_cidr" {
}

variable "zone_name" {
}

variable "master_ips" {
  type = list(string)
}

variable "om_public_ip" {}
variable "pas_elb_dns" {}
variable "control_plane_om_public_ip" {}
variable "control_plane_plane_elb_dns" {}
variable "postfix_private_ip" {}
variable "splunk_search_head_elb_dns" {}
variable "splunk_logs_private_ip" {}
variable "splunk_monitor_elb_dns" {}

module "domains" {
  source      = "../../domains"
  root_domain = "${var.zone_name}"
}

data "template_file" "named_conf_content" {
  template = file("${path.module}/named.conf.tpl")

  vars = {
    client_cidr = var.client_cidr
    zone_name   = var.zone_name
  }
}

output "named_conf_content" {
  value = data.template_file.named_conf_content.rendered
}

output "zone_content" {
  value = templatefile("${path.module}/db.zone.tpl", {
    zone_name  = var.zone_name,
    master_ips = var.master_ips,

    om_public_ip                = var.om_public_ip,
    pas_elb_dns                 = var.pas_elb_dns,
    postfix_private_ip          = var.postfix_private_ip,
    splunk_search_head_elb_dns  = var.splunk_search_head_elb_dns,
    splunk_logs_private_ip      = var.splunk_logs_private_ip,
    splunk_monitor_elb_dns      = var.splunk_monitor_elb_dns,
    control_plane_om_public_ip  = var.control_plane_om_public_ip,
    control_plane_plane_elb_dns = var.control_plane_plane_elb_dns,

    om_subdomain     = module.domains.om_subdomain,
    system_subdomain = module.domains.system_subdomain,
    apps_subdomain   = module.domains.apps_subdomain,

    control_plane_om_subdomain    = module.domains.control_plane_om_subdomain,
    control_plane_plane_subdomain = module.domains.control_plane_plane_subdomain,

    smtp_subdomain = module.domains.smtp_subdomain,

    splunk_subdomain         = module.domains.splunk_subdomain,
    splunk_logs_subdomain    = module.domains.splunk_logs_subdomain,
    splunk_monitor_subdomain = module.domains.splunk_monitor_subdomain,
  })
}