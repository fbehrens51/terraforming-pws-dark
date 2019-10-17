variable "server_cert" {}
variable "server_key" {}
variable "ca_cert" {}
variable "user_data_path" {}
variable "root_domain" {}
variable "clamav_db_mirror" {}
variable "custom_clamav_yum_repo_url" {}
variable "splunk_password" {}
variable "splunk_rpm_version" {}
variable "splunk_rpm_s3_bucket" {}
variable "splunk_rpm_s3_region" {}
variable "role_name" {}
variable "public_bucket_name" {}
variable "public_bucket_url" {}

module "splunk_ports" {
  source = "../../../../modules/splunk_ports"
}

module "syslog_config" {
  source                = "../../../../modules/syslog"
  root_domain           = "${var.root_domain}"
  splunk_syslog_ca_cert = "${var.ca_cert}"
  public_bucket_name    = "${var.public_bucket_name}"
  public_bucket_url     = "${var.public_bucket_url}"
  role_name             = "${var.role_name}"
}

module "clam_av_client_config" {
  source           = "../../../../modules/clamav/amzn2_systemd_client"
  clamav_db_mirror = "${var.clamav_db_mirror}"
  custom_repo_url  = "${var.custom_clamav_yum_repo_url}"
}

data "template_file" "web_conf" {
  template = <<EOF
[settings]
httpport           = ${module.splunk_ports.splunk_web_port}
mgmtHostPort       = 127.0.0.1:${module.splunk_ports.splunk_mgmt_port}

enableSplunkWebSSL = true
serverCert         = /opt/splunk/etc/auth/mycerts/mySplunkWebCertificate.pem
privKeyPath        = /opt/splunk/etc/auth/mycerts/mySplunkWebPrivateKey.key
EOF
}

data "template_file" "cloud_config" {
  template = <<EOF
#cloud-config
bootcmd:
  - mkdir -p /opt/splunk
  - while [ ! -e /dev/xvdf ] ; do sleep 1 ; done
  - if [ "$(file -b -s /dev/xvdf)" == "data" ]; then mkfs -t ext4 /dev/xvdf; fi

mounts:
  - [ "/dev/xvdf", "/opt/splunk", "ext4", "defaults,nofail", "0", "2" ]

write_files:
- path: /tmp/web.conf
  content: |
    ${indent(4, data.template_file.web_conf.rendered)}

- path: /tmp/server.crt
  content: |
    ${indent(4, var.server_cert)}

- path: /tmp/server.key
  content: |
    ${indent(4, var.server_key)}


runcmd:
  - |
    set -ex

    hostname ${var.role_name}-`hostname`
    echo `hostname` > /etc/hostname
    sed -i 's/localhost$/localhost '`hostname`'/' /etc/hosts

    mkdir -p /opt/splunk/etc/system/local/
    mkdir -p /opt/splunk/etc/auth/mycerts/

    cp /tmp/web.conf /opt/splunk/etc/system/local/web.conf
    cp /tmp/server.crt /opt/splunk/etc/auth/mycerts/mySplunkWebCertificate.pem
    cp /tmp/server.key /opt/splunk/etc/auth/mycerts/mySplunkWebPrivateKey.key

    aws s3 cp s3://${var.splunk_rpm_s3_bucket}/ . --recursive --exclude='*' --include='splunk/splunk-${var.splunk_rpm_version}*' --region ${var.splunk_rpm_s3_region}
    sudo rpm -i splunk/splunk-${var.splunk_rpm_version}*.rpm

    /opt/splunk/bin/splunk enable boot-start -systemd-managed 1 --no-prompt --accept-license --answer-yes

    # https://docs.splunk.com/Documentation/Splunk/7.3.1/Admin/RunSplunkassystemdservice#Configure_systemd_using_enable_boot-start
    # this file is created when we run splunk enable boot-start, so here we are setting it to exit cleanly when the instance terminates.
    cat <<END >> /etc/systemd/system/Splunkd.service
    [Service]
    KillMode=mixed
    KillSignal=SIGINT
    TimeoutStopSec=10min
    END
    systemctl daemon-reload

    /opt/splunk/bin/splunk start
    /opt/splunk/bin/splunk cmd splunkd rest --noauth POST /services/authentication/users "name=admin&password=${var.splunk_password}&roles=admin"
    /opt/splunk/bin/splunk restart
EOF
}

data "template_cloudinit_config" "user_data" {
  base64_encode = false
  gzip          = false

  part {
    filename     = "syslog.cfg"
    content      = "${module.syslog_config.user_data}"
    content_type = "text/x-include-url"
  }

  part {
    filename     = "custom.cfg"
    content_type = "text/cloud-config"
    content      = "${file(var.user_data_path)}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "clamav.cfg"
    content_type = "text/cloud-config"
    content      = "${module.clam_av_client_config.client_user_data_config}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "splunk-and-web.cfg"
    content_type = "text/cloud-config"
    content      = "${data.template_file.cloud_config.rendered}"
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }
}

output "user_data" {
  value = "${data.template_cloudinit_config.user_data.rendered}"
}
