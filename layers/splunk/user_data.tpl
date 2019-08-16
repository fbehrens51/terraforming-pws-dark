#cloud-config
users:
  - default

bootcmd:
  - mkdir -p /opt/splunk
  - while [ ! -e /dev/xvdf ] ; do sleep 1 ; done
  - if [ "$(file -b -s /dev/xvdf)" == "data" ]; then mkfs -t ext4 /dev/xvdf; fi

write_files:
- path: /tmp/server.conf
  content: |
    ${indent(4, server_conf_content)}

- path: /tmp/web.conf
  content: |
    ${indent(4, web_conf_content)}

- path: /tmp/inputs.conf
  content: |
    ${indent(4, inputs_conf_content)}

- path: /tmp/outputs.conf
  content: |
    ${indent(4, outputs_conf_content)}

- path: /tmp/http_inputs.conf
  content: |
    ${indent(4, http_inputs_conf_content)}

- path: /tmp/server.crt
  content: |
    ${indent(4, server_cert_content)}

- path: /tmp/server.key
  content: |
    ${indent(4, server_key_content)}

- path: /tmp/splunk_forwarder.conf
  content: |
    ${indent(4, splunk_forwarder_app_conf)}

mounts:
  - [ "/dev/xvdf", "/opt/splunk", "ext4", "defaults,nofail", "0", "2" ]

runcmd:
  - |
    set -ex
    hostname ${role}-`hostname`
    echo `hostname` > /etc/hostname
    sed -i 's/localhost$/localhost '`hostname`'/' /etc/hosts
    mkdir -p /opt/splunk
    aws s3 cp s3://${splunk_rpm_s3_bucket}/ . --recursive --exclude='*' --include='splunk-${splunk_rpm_version}*' --region ${splunk_rpm_s3_region}
    sudo rpm -i splunk-${splunk_rpm_version}*.rpm

    mkdir -p /opt/splunk/etc/auth/mycerts
    mkdir -p /opt/splunk/etc/apps/splunk_httpinput/local/
    mkdir -p /opt/splunk/etc/apps/SplunkForwarder/local/

    cp /tmp/server.crt /opt/splunk/etc/auth/mycerts/mySplunkWebCertificate.pem
    cp /tmp/server.key /opt/splunk/etc/auth/mycerts/mySplunkWebPrivateKey.key

    cp /tmp/inputs.conf /opt/splunk/etc/system/local/inputs.conf
    cp /tmp/outputs.conf /opt/splunk/etc/system/local/outputs.conf
    cp /tmp/http_inputs.conf /opt/splunk/etc/apps/splunk_httpinput/local/inputs.conf
    cp /tmp/splunk_forwarder.conf /opt/splunk/etc/apps/SplunkForwarder/local/app.conf
    cp /tmp/server.conf /opt/splunk/etc/system/local/server.conf
    cp /tmp/web.conf /opt/splunk/etc/system/local/web.conf

    /opt/splunk/bin/splunk enable boot-start -systemd-managed 1 --no-prompt --accept-license --answer-yes

    # https://docs.splunk.com/Documentation/Splunk/7.3.1/Admin/RunSplunkassystemdservice#Configure_systemd_using_enable_boot-start
    cat <<EOF >> /etc/systemd/system/Splunkd.service
    [Service]
    KillMode=mixed
    KillSignal=SIGINT
    TimeoutStopSec=10min
    EOF
    systemctl daemon-reload

    /opt/splunk/bin/splunk start
    /opt/splunk/bin/splunk cmd splunkd rest --noauth POST /services/authentication/users "name=admin&password=${password}&roles=admin"
    /opt/splunk/bin/splunk restart

