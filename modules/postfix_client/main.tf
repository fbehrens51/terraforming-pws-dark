variable "public_bucket_name" {
}

variable "public_bucket_url" {
}

variable "root_domain" {
}

variable "smtp_from" {
}

module "domains" {
  source      = "../domains"
  root_domain = var.root_domain
}

locals {
  bucket_key = "postfix-client-${md5(data.template_file.user_data.rendered)}-user-data.yml"
}

data "template_file" "user_data" {
  template = <<EOF
#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]

runcmd:
  - |
    set -ex
    usermod -c "root@$(hostname -s)" root

    echo "@$(hostname -s).${var.root_domain} ${var.smtp_from}" > /etc/postfix/generic
    postconf -e \
      relayhost="[${module.domains.smtp_fqdn}]" \
      mydestination= \
      myhostname="$(hostname -s).${var.root_domain}" \
      mydomain="${var.root_domain}" \
      local_transport='error: local delivery disabled' \
      smtp_fallback_relay= \
      smtp_generic_maps=hash:/etc/postfix/generic \
      smtp_tls_CAfile=/etc/ssl/certs/ca-bundle.crt \
      smtp_tls_note_starttls_offer=yes \
      smtp_use_tls=yes

    postmap hash:/etc/postfix/generic
    systemctl restart postfix.service

packages:
 - postfix
 - mailx

EOF
}

resource "aws_s3_bucket_object" "user_data" {
  bucket  = var.public_bucket_name
  key     = local.bucket_key
  content = data.template_file.user_data.rendered
}

output "postfix_client_user_data" {
  value = <<EOF
#include
${var.public_bucket_url}/${local.bucket_key}
EOF
}
