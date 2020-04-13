variable "customer_banner_user_data" {
}

variable "clamav_db_mirror" {
}

variable "clamav_deb_pkg_object_url" {
}

variable "user_accounts_user_data" {
}

variable "node_exporter_user_data" {
}

variable "trusted_ca_certs" {
}

module "clamav_config" {
  source           = "../clamav/ubuntu_systemd_client"
  clamav_db_mirror = var.clamav_db_mirror
  deb_tgz_location = var.clamav_deb_pkg_object_url
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
    content_type = "text/cloud-config"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
    content      = <<CLOUDINIT

ca-certs:
  remove-defaults: true

bootcmd:
  # Disable SSL in postgres.  Otherwise, postgres will fail to start since the
  # snakeoil certificate is missing.  Note that OM connect to postgres over the
  # unix socket.
  - sudo sed -i 's/^ssl = true/#ssl = true/' /etc/postgresql/*/main/postgresql.conf

# We cannot use cloud-init `ca-certs` to set the trusted CAs. cloud-init will
# put all the certs in a single file,
# i.e. /etc/ssl/certs/cloud-init-ca-certs.pem. This will cause /etc/ssl/certs
# to have a single symlink, e.g.:
#
# 02db8165.0 -> cloud-init-ca-certs.crt
#
# As opposed to the having multiple symlinks, such as:
#
# bef70e06.0 -> cloud_init_ca_cert_1.pem
# 09789157.0 -> cloud_init_ca_cert_2.pem
# 653b494a.0 -> cloud_init_ca_cert_3.pem
#
# Many libraries do certificates lookup using the cert hash. In particular, I
# believe the AWS CPI breaks if not all CA certificates have a symlink.


write_files:
- path: /run/certs.crt
  content: |
    ${indent(4, var.trusted_ca_certs)}

runcmd:
  - |
    set -ex

    echo "deleting old certificates"
    rm -f /usr/local/share/ca-certificates/cloud_init_ca_cert_*

    # Split files on '----END CERTIFICATE-----' and increment our file counter by 1
    awk -v n=1 '
      split_after == 1 {n++;split_after=0}
      /-----END CERTIFICATE-----/ {split_after=1}
      NF {print > "/usr/local/share/ca-certificates/cloud_init_ca_cert_" n ".crt"}' < /run/certs.crt

    updated_certs=1
    retry_count=0
    max_retry_count=3

    set +e
    until [ $updated_certs -eq 0 ] || [ $retry_count -ge $max_retry_count ]; do
      echo "trying to run update-ca-certificates..."
      timeout --signal=KILL 60s /usr/sbin/update-ca-certificates -f -v
      updated_certs=$?
      retry_count=$((retry_count + 1))
    done
    set -e

    if [ $updated_certs -ne 0 ]; then
      echo "failed to setup ca certificates"
      exit 1
    fi
CLOUDINIT
  }

  part {
    filename     = "clamav.cfg"
    content_type = "text/cloud-config"
    content      = module.clamav_config.client_user_data_config
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "node_exporter.cfg"
    content_type = "text/cloud-config"
    content      = var.node_exporter_user_data
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
