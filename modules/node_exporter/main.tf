variable "public_bucket_name" {
}

variable "public_bucket_url" {
}

variable "node_exporter_location" {
}

variable "server_cert_pem" {
}

variable "server_key_pem" {
}

locals {
  bucket_key = "node_exporter-${md5(data.template_file.user_data.rendered)}-user-data.yml"
}

data "template_file" "user_data" {
  template = <<EOF
#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]

users:
- name: node_exporter
  system: true

write_files:
  - content: |
      ${indent(6, var.server_key_pem)}
    path: /etc/node_exporter/key.pem
    permissions: '0644'
    owner: root:root

  - content: |
      ${indent(6, var.server_cert_pem)}
    path: /etc/node_exporter/cert.pem
    permissions: '0644'
    owner: root:root

  - content: |
      tlsConfig:
        tlsCertPath: /etc/node_exporter/cert.pem
        tlsKeyPath: /etc/node_exporter/key.pem
    path: /etc/node_exporter/web-config.yml
    permissions: '0644'
    owner: root:root

  - content: |
      OPTIONS="--collector.systemd --web.config=\"/etc/node_exporter/web-config.yml\""
    path: /etc/sysconfig/node_exporter
    permissions: '0644'
    owner: root:root

  - content: |
      [Unit]
      Description=Node Exporter

      [Service]
      User=node_exporter
      EnvironmentFile=/etc/sysconfig/node_exporter
      ExecStart=/usr/sbin/node_exporter $OPTIONS

      [Install]
      WantedBy=multi-user.target
    path: /usr/lib/systemd/system/node_exporter.service
    permissions: '0644'
    owner: root:root

runcmd:
  - |
    set -ex
    mkdir node_exporter
    cd node_exporter
    wget --quiet --no-check-certificate -O - "${var.node_exporter_location}" | tar xzf - --strip-components=1
    mv node_exporter /usr/sbin/node_exporter
    systemctl daemon-reload
    systemctl start node_exporter
    systemctl enable node_exporter.service
EOF

}

resource "aws_s3_bucket_object" "user_data" {
  count   = var.node_exporter_location == "" ? 0 : 1
  bucket  = var.public_bucket_name
  key     = local.bucket_key
  content = data.template_file.user_data.rendered
}

output "user_data" {
  value = <<EOF
%{if var.node_exporter_location != ""}
#include
${var.public_bucket_url}/${local.bucket_key}
%{else}
#!/bin/sh
echo "node_exporter_object_url missing from the paperwork layer.."
echo "skipping setup for metrics"
%{endif}
EOF
}
