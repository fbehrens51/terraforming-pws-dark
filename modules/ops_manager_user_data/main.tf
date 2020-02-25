variable "customer_banner_user_data" {
}

variable "clamav_client_user_data" {
}

variable "user_accounts_user_data" {
}

variable "trusted_ca_certs" {
}

data "template_cloudinit_config" "config" {
  base64_encode = true
  gzip          = true

  part {
    filename     = "user_accounts_user_data.cfg"
    content_type = "text/x-include-url"
    content      = var.user_accounts_user_data
  }

  part {
    filename     = "certs.cfg"
    content_type = "text/cloud-config"
    content      = <<CLOUDINIT
ca-certs:
  # remove all the default trusted CA certificates that are normally shipped
  # with Ubuntu.
  remove-defaults: true

  # The following are the CAs used in the AWS EC2 and S3 endpoint cert chain.
  trusted:
  - |
    ${indent(4, var.trusted_ca_certs)}
CLOUDINIT

  }

  part {
    content_type = "text/cloud-config"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
    content      = <<CLOUDINIT
bootcmd:
  # Disable SSL in postgres.  Otherwise, postgres will fail to start since the
  # snakeoil certificate is missing.  Note that OM connect to postgres over the
  # unix socket.
  - sudo sed -i 's/^ssl = true/#ssl = true/' /etc/postgresql/*/main/postgresql.conf
CLOUDINIT
  }

  part {
    filename     = "clamav.cfg"
    content_type = "text/cloud-config"
    content      = var.clamav_client_user_data
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "banner.cfg"
    content_type = "text/x-include-url"
    content      = var.customer_banner_user_data
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }
}

output "cloud_config" {
  value = data.template_cloudinit_config.config.rendered
}
