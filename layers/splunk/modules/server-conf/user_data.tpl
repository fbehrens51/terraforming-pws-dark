#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
- path: /tmp/server.conf
  content: |
    ${indent(4, server_conf_content)}

runcmd:
  - |
    set -ex

    mkdir -p /opt/splunk/etc/system/local/
    cp /tmp/server.conf /opt/splunk/etc/system/local/server.conf
