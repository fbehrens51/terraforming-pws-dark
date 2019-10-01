#cloud-config
write_files:
- path: /tmp/license.lic
  content: |
    ${indent(4, file(license_path))}

runcmd:
  - |
    set -ex

    mkdir -p /opt/splunk/etc/licenses/enterprise

    cp /tmp/license.lic /opt/splunk/etc/licenses/enterprise/License.lic

