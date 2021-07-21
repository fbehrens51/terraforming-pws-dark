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
  shell: /sbin/nologin

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
      tls_server_config:
        cert_file: /etc/node_exporter/cert.pem
        key_file: /etc/node_exporter/key.pem
        cipher_suites:
          - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
          - TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
          - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
          - TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256

    path: /etc/node_exporter/web-config.yml
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
    wget --quiet --no-check-certificate -O - "${var.node_exporter_location}" | tar --strip-components=1 --wildcards -xzf - '*/node_exporter'
    install -o root -g root -m 755 node_exporter /usr/sbin
    rm node_exporter
    METADATA=$(command -v ec2metadata || command -v ec2-metadata) # commands are named different on AL2 vs Xenial
    echo "OPTIONS=--collector.systemd --web.config=/etc/node_exporter/web-config.yml --web.listen-address=$($METADATA -o | cut -d' ' -f2):9100" > /etc/sysconfig/node_exporter
    chmod 644 /etc/sysconfig/node_exporter
    chown root:root /etc/sysconfig/node_exporter
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
