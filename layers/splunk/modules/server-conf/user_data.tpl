#cloud-config
write_files:
- path: /tmp/server.conf
  content: |
    ${indent(4, server_conf_content)}

- path: /tmp/splunk-ca.pem
  content: |
    ${indent(4, ca_cert_content)}

runcmd:
  - |
    set -ex

    mkdir -p /opt/splunk/etc/system/local/
    mkdir -p /opt/splunk/etc/auth/mycerts/

    cp /tmp/server.conf /opt/splunk/etc/system/local/server.conf
    cp /tmp/splunk-ca.pem /opt/splunk/etc/auth/mycerts/mySplunkCACertificate.pem
