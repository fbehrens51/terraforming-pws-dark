#cloud-config
write_files:
- path: /tmp/server.conf
  content: |
    ${indent(4, server_conf_content)}

runcmd:
  - |
    set -ex

    mkdir -p /opt/splunk/etc/system/local/
    cp /tmp/server.conf /opt/splunk/etc/system/local/server.conf
