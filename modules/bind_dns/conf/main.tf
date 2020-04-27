variable "client_cidr" {
}

variable "zone_name" {
}

variable "master_ips" {
  type = list(string)
}

variable "shared_alb" {}
variable "pas_elb_dns" {}
variable "control_plane_plane_elb_dns" {}
variable "postfix_private_ip" {}
variable "splunk_logs_private_ip" {}
variable "fluentd_private_ip" {}

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

    shared_alb = var.shared_alb,
    pas_elb_dns                 = var.pas_elb_dns,
    postfix_private_ip          = var.postfix_private_ip,
    splunk_logs_private_ip      = var.splunk_logs_private_ip,
    fluentd_private_ip          = var.fluentd_private_ip,
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
    grafana_subdomain        = module.domains.grafana_subdomain,

    fluentd_subdomain = module.domains.fluentd_subdomain,
  })
}
