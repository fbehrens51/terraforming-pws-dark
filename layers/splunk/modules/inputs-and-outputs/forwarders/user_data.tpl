#cloud-config
write_files:
- path: /tmp/inputs.conf
  content: |
    ${indent(4, inputs_conf_content)}

- path: /tmp/outputs.conf
  content: |
    ${indent(4, outputs_conf_content)}

- path: /tmp/http_inputs.conf
  content: |
    ${indent(4, http_inputs_conf_content)}

- path: /tmp/splunk_forwarder.conf
  content: |
    ${indent(4, splunk_forwarder_app_conf)}

runcmd:
  - |
    set -ex

    mkdir -p /opt/splunk/etc/apps/splunk_httpinput/local/
    mkdir -p /opt/splunk/etc/apps/SplunkForwarder/local/

    cp /tmp/inputs.conf /opt/splunk/etc/system/local/inputs.conf
    cp /tmp/outputs.conf /opt/splunk/etc/system/local/outputs.conf
    cp /tmp/http_inputs.conf /opt/splunk/etc/apps/splunk_httpinput/local/inputs.conf
    cp /tmp/splunk_forwarder.conf /opt/splunk/etc/apps/SplunkForwarder/local/app.conf
    cp /tmp/web.conf /opt/splunk/etc/system/local/web.conf

