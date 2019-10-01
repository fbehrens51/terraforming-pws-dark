#cloud-config
write_files:
- path: /tmp/inputs.conf
  content: |
    ${indent(4, inputs_conf_content)}

runcmd:
  - |
    set -ex

    mkdir -p /opt/splunk/etc/system/local/
    cp /tmp/inputs.conf /opt/splunk/etc/system/local/inputs.conf
