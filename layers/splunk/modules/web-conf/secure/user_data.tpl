#cloud-config
write_files:
- path: /tmp/web.conf
  content: |
    ${indent(4, web_conf_content)}

- path: /tmp/server.crt
  content: |
    ${indent(4, server_cert_content)}

- path: /tmp/server.key
  content: |
    ${indent(4, server_key_content)}

runcmd:
  - |
    set -ex

    mkdir -p /opt/splunk/etc/system/local/
    cp /tmp/web.conf /opt/splunk/etc/system/local/web.conf

    mkdir -p /opt/splunk/etc/auth/mycerts/
    cp /tmp/server.crt /opt/splunk/etc/auth/mycerts/mySplunkWebCertificate.pem
    cp /tmp/server.key /opt/splunk/etc/auth/mycerts/mySplunkWebPrivateKey.key

