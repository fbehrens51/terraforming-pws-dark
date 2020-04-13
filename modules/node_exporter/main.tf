variable "public_bucket_name" {
}

variable "public_bucket_url" {
}

variable "node_exporter_location" {
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
      OPTIONS="--collector.systemd"
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
  bucket  = var.public_bucket_name
  key     = local.bucket_key
  content = data.template_file.user_data.rendered
}

output "user_data" {
  value = <<EOF
#include
${var.public_bucket_url}/${local.bucket_key}
EOF
}
