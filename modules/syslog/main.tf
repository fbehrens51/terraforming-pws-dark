variable "root_domain" {}
variable "splunk_syslog_ca_cert" {}

module "domains" {
  source = "../domains"

  root_domain = "${var.root_domain}"
}

module "splunk_ports" {
  source = "../splunk_ports"
}

data "template_file" "user_data" {
  template = <<EOF
bootcmd:
  - |
    set -ex
    yum install rsyslog-gnutls -y

write_files:
  - content: |
      ${indent(6, var.splunk_syslog_ca_cert)}
    path: /etc/rsyslog.d/ca.pem
    permissions: '0400'
    owner: root:root

rsyslog:
  remotes:
    splunk: "@@${module.domains.splunk_logs_fqdn}:${module.splunk_ports.splunk_tcp_port}"
  configs:
    - filename: 10-tls.conf
      content: |
        $DefaultNetstreamDriverCAFile /etc/rsyslog.d/ca.pem
        $ActionSendStreamDriver gtls
        $ActionSendStreamDriverMode 1
        $ActionSendStreamDriverAuthMode x509/name
        $ActionSendStreamDriverPermittedPeer ${module.domains.splunk_logs_fqdn}
EOF
}

output "user_data" {
  value = "${data.template_file.user_data.rendered}"
}
