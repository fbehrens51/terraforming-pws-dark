variable "root_domain" {}
variable "splunk_syslog_ca_cert" {}
variable "public_bucket_name" {}
variable "public_bucket_url" {}
variable "role_name" {}

module "domains" {
  source = "../domains"

  root_domain = "${var.root_domain}"
}

module "splunk_ports" {
  source = "../splunk_ports"
}

locals {
  bucket_key = "${var.role_name}-${md5(data.template_file.user_data.rendered)}-syslog-user-data.yml"
}

data "template_file" "user_data" {
  template = <<EOF
#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]

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

resource "aws_s3_bucket_object" "user_data" {
  bucket  = "${var.public_bucket_name}"
  key     = "${local.bucket_key}"
  content = "${data.template_file.user_data.rendered}"
}

output "user_data" {
  value = <<EOF
#include
${var.public_bucket_url}/${local.bucket_key}
EOF
}
