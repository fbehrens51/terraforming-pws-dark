#cloud-config
write_files:
- path: /tmp/inputs.conf
  content: |
    ${indent(4, inputs_conf_content)}

- path: /tmp/server_cert.pem
  content: |
    ${indent(4, server_cert)}
    ${indent(4, server_key)}
    ${indent(4, ca_cert)}

runcmd:
  - |
    set -ex

    mkdir -p /opt/splunk/etc/system/local/
    mkdir -p /opt/splunk/etc/auth/mycerts

    cp /tmp/server_cert.pem /opt/splunk/etc/auth/mycerts/mySplunkServerCertificate.pem

    cp /tmp/inputs.conf /opt/splunk/etc/system/local/inputs.conf
