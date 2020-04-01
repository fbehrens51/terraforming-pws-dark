variable "server_cert" {
}

variable "server_key" {
}

variable "ca_cert" {
}

variable "user_accounts_user_data" {
}

variable "root_domain" {
}

variable "clamav_user_data" {
}

variable "splunk_password" {
}

variable "splunk_rpm_version" {
}


variable "region" {
}

variable "role_name" {
}

variable "public_bucket_name" {
}

variable "public_bucket_url" {
}

variable "banner_user_data" {
}

variable "instance_user_data" {
}

module "splunk_ports" {
  source = "../../../../modules/splunk_ports"
}

module "syslog_config" {
  source                = "../../../../modules/syslog"
  root_domain           = var.root_domain
  splunk_syslog_ca_cert = var.ca_cert
  public_bucket_name    = var.public_bucket_name
  public_bucket_url     = var.public_bucket_url
  role_name             = var.role_name
}

data "template_file" "web_conf" {
  template = <<EOF
[settings]
updateCheckerBaseURL = 0
httpport             = ${module.splunk_ports.splunk_web_port}
mgmtHostPort         = 127.0.0.1:${module.splunk_ports.splunk_mgmt_port}

enableSplunkWebSSL = true
serverCert         = /opt/splunk/etc/auth/mycerts/mySplunkWebCertificate.pem
privKeyPath        = /opt/splunk/etc/auth/mycerts/mySplunkWebPrivateKey.key
EOF

}

data "template_file" "telemetry_conf" {
  template = <<EOF
[general]
sendLicenseUsage = false
sendAnonymizedUsage = false
sendAnonymizedWebAnalytics = false
sendSupportUsage = false
EOF

}

data "template_file" "cloud_config" {
  template = <<EOF
#cloud-config
bootcmd:
  - |
    mkdir -p /opt/splunk
    while [ ! -e /dev/sdf ] ; do sleep 1 ; done
    if [ "$(file -b -s -L /dev/sdf)" == "data" ]; then mkfs -t ext4 /dev/sdf; fi

mounts:
  - [ "/dev/sdf", "/opt/splunk", "ext4", "defaults,nofail", "0", "2" ]

write_files:
- path: /run/splunk-ca.pem
  content: |
    ${indent(4, var.ca_cert)}

- path: /run/server.crt
  content: |
    ${indent(4, var.server_cert)}

- path: /run/server.key
  content: |
    ${indent(4, var.server_key)}

- path: /run/web.conf
  content: |
    ${indent(4, data.template_file.web_conf.rendered)}

- path: /run/telemetry.conf
  content: |
    ${indent(4, data.template_file.telemetry_conf.rendered)}

runcmd:
  - |
    set -ex

    hostname ${var.role_name}-`hostname`
    echo `hostname` > /etc/hostname
    sed -i 's/localhost$/localhost '`hostname`'/' /etc/hosts

    mkdir -p /opt/splunk/etc/system/local/
    mkdir -p /opt/splunk/etc/auth/mycerts/
    mkdir -p /opt/splunk/etc/apps/splunk_instrumentation/local/

    cp /run/web.conf /opt/splunk/etc/system/local/web.conf
    cp /run/server.crt /opt/splunk/etc/auth/mycerts/mySplunkWebCertificate.pem
    cp /run/server.key /opt/splunk/etc/auth/mycerts/mySplunkWebPrivateKey.key
    cp /run/telemetry.conf /opt/splunk/etc/apps/splunk_instrumentation/local/telemetry.conf

    aws --region ${var.region} s3 cp --no-progress s3://${var.public_bucket_name}/ . --recursive --exclude='*' --include='splunk/${var.splunk_rpm_version}'
    rpm -i splunk/${var.splunk_rpm_version}

    /opt/splunk/bin/splunk enable boot-start -systemd-managed 1 --no-prompt --accept-license --answer-yes

    # https://docs.splunk.com/Documentation/Splunk/7.3.1/Admin/RunSplunkassystemdservice#Configure_systemd_using_enable_boot-start
    # this file is created when we run splunk enable boot-start, so here we are setting it to exit cleanly when the instance terminates.
    cat <<END >> /etc/systemd/system/Splunkd.service
    [Service]
    KillMode=mixed
    KillSignal=SIGINT
    TimeoutStopSec=10min
    LimitNPROC=16000
    END
    systemctl daemon-reload

    /opt/splunk/bin/splunk start
    /opt/splunk/bin/splunk cmd splunkd rest --noauth POST /services/authentication/users "name=admin&password=${var.splunk_password}&roles=admin"
    /opt/splunk/bin/splunk restart
EOF

}

data "template_cloudinit_config" "user_data" {
  base64_encode = true
  gzip          = true

  part {
    filename     = "syslog.cfg"
    content      = module.syslog_config.user_data
    content_type = "text/x-include-url"
  }

  part {
    filename     = "user_accounts_user_data.cfg"
    content_type = "text/x-include-url"
    content      = var.user_accounts_user_data
  }

  part {
    filename     = "clamav.cfg"
    content_type = "text/x-include-url"
    content      = var.clamav_user_data
  }

  part {
    filename     = "splunk-and-web.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.cloud_config.rendered
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "specific-instance.cfg"
    content_type = "text/cloud-config"
    content      = var.instance_user_data
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }

  part {
    filename     = "banner.cfg"
    content_type = "text/x-include-url"
    content      = var.banner_user_data
    merge_type   = "list(append)+dict(no_replace,recurse_list)"
  }
}

output "user_data" {
  value = data.template_cloudinit_config.user_data.rendered
}

