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

- path: /tmp/http_inputs.conf
  content: |
    ${indent(4, http_inputs_conf_content)}

- path: /tmp/server.crt
  content: |
    ${indent(4, server_cert_content)}

- path: /tmp/server.key
  content: |
    ${indent(4, server_key_content)}

mounts:
  - [ "/dev/xvdf", "/opt/splunk", "ext4", "defaults,nofail", "0", "2" ]

runcmd:
  - hostname ${role}-`hostname`
  - echo `hostname` > /etc/hostname
  - sed -i 's/localhost$/localhost '`hostname`'/' /etc/hosts
  - mkdir /opt/splunk
  - aws s3 cp s3://${splunk_rpm_s3_bucket}/ . --recursive --exclude='*' --include='splunk-${splunk_rpm_version}*' --region ${splunk_rpm_s3_region}
  - sudo rpm -i splunk-${splunk_rpm_version}*.rpm

  - mkdir -p /opt/splunk/etc/auth/mycerts
  - mkdir -p /opt/splunk/etc/apps/splunk_httpinput/local/

  - cp /tmp/server.crt /opt/splunk/etc/auth/mycerts/mySplunkWebCertificate.pem
  - cp /tmp/server.key /opt/splunk/etc/auth/mycerts/mySplunkWebPrivateKey.key

  - cp /tmp/inputs.conf /opt/splunk/etc/system/local/inputs.conf
  - cp /tmp/http_inputs.conf /opt/splunk/etc/apps/splunk_httpinput/local/inputs.conf
  - cp /tmp/server.conf /opt/splunk/etc/system/local/server.conf
  - cp /tmp/web.conf /opt/splunk/etc/system/local/web.conf

  - /opt/splunk/bin/splunk start --no-prompt --accept-license --answer-yes
  - /opt/splunk/bin/splunk cmd splunkd rest --noauth POST /services/authentication/users "name=admin&password=${password}&roles=admin"
  - /opt/splunk/bin/splunk restart
