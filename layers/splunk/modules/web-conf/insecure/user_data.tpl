#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
- path: /tmp/web.conf
  content: |
    ${indent(4, web_conf_content)}

runcmd:
  - |
    set -ex

    mkdir -p /opt/splunk/etc/system/local/
    cp /tmp/web.conf /opt/splunk/etc/system/local/web.conf

