variable "root_domain" {}

module "domains" {
  source = "../domains"

  root_domain = "${var.root_domain}"
}

module "splunk_ports" {
  source = "../splunk_ports"
}

data "template_file" "user_data" {
  template = <<EOF
rsyslog:
    remotes:
        splunk: "@@${module.domains.splunk_logs_fqdn}:${module.splunk_ports.splunk_tcp_port}"
EOF
}

output "user_data" {
  value = "${data.template_file.user_data.rendered}"
}
