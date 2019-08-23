#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
- path: /tmp/license.conf
  content: |
    ${indent(4, license_conf_content)}

runcmd:
  - |
    set -ex

    mkdir -p /opt/splunk/etc/apps/SplunkLicenseSettings/local/

    cp /tmp/license.conf /opt/splunk/etc/apps/SplunkLicenseSettings/local/server.conf

