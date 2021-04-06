variable "root_domain" {
}

variable "syslog_ca_cert" {
}

variable "public_bucket_name" {
}

variable "public_bucket_url" {
}

variable "role_name" {
}

variable "forward_locally" {
  type    = bool
  default = false
}

module "domains" {
  source = "../domains"

  root_domain = var.root_domain
}

module "syslog_ports" {
  source = "../syslog_ports"
}

locals {
  bucket_key = "${var.role_name}-${md5(local.user_data)}-syslog-user-data.yml"

  user_data = <<EOF
#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]

packages:
 - rsyslog-gnutls
package_reboot_if_required: true

write_files:
  - content: |
      ${indent(6, var.syslog_ca_cert)}
    path: /etc/rsyslog.d/ca.pem
    permissions: '0400'
    owner: root:root

  - content: |
      # This file controls the configuration of the syslog plugin.
      # It simply takes events and writes them to syslog. The
      # arguments provided can be the default priority that you
      # want the events written with. And optionally, you can give
      # a second argument indicating the facility that you want events
      # logged to. Valid options are LOG_LOCAL0 through 7, LOG_AUTH,
      # LOG_AUTHPRIV, LOG_DAEMON, LOG_SYSLOG, and LOG_USER.

      active = yes
      direction = out
      path = builtin_syslog
      type = builtin
      args = LOG_INFO
      format = string
    path: /etc/audisp/plugins.d/syslog.conf
    permissions: '0640'
    owner: root:root

%{if var.forward_locally}
  - content: |
      127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
      ::1         localhost6 localhost6.localdomain6

      127.0.0.1   ${module.domains.fluentd_fqdn}
    path: /etc/hosts
    permissions: '0644'
    owner: root:root
%{endif}

rsyslog:
  remotes:
    fluentd: "@@${module.domains.fluentd_fqdn}:${module.syslog_ports.syslog_port}"
  configs:
    - filename: 10-tls.conf
      content: |
        $DefaultNetstreamDriverCAFile /etc/rsyslog.d/ca.pem
        $ActionSendStreamDriver gtls
        $ActionSendStreamDriverMode 1
        $ActionSendStreamDriverAuthMode x509/name
        $ActionSendStreamDriverPermittedPeer ${module.domains.fluentd_fqdn}

runcmd:
  - |
    set -ex
    service auditd reload
    systemctl reload-or-restart rsyslog
EOF

}

resource "aws_s3_bucket_object" "user_data" {
  bucket  = var.public_bucket_name
  key     = local.bucket_key
  content = local.user_data
}

output "user_data" {
  value = <<EOF
#include
${var.public_bucket_url}/${local.bucket_key}
EOF

}

