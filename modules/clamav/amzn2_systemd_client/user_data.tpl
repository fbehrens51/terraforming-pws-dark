#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]
write_files:
  -   content: |
        ${clam_freshclam}
      path: /usr/lib/systemd/system/clam-freshclam.service
      permissions: '0644'
      owner: root:root
yum_repos:
  custom-clamav-repo:
      name: "Custom repo added for ClamAV installation"
      baseurl: ${custom_repo_url}
      enabled: true
      gpgcheck: false
packages:
  - clamav
  - clamd
  - augeas
runcmd:
  - |
    set -ex
    augtool set /files/etc/freshclam.conf/LogSyslog yes
    augtool rm /files/etc/freshclam.conf/DatabaseMirror
    augtool set /files/etc/freshclam.conf/PrivateMirror ${clam_database_mirror}
    augtool set /files/etc/freshclam.conf/Checks 24
    augtool rm /files/etc/clamd.d/scan.conf/Example
    augtool set /files/etc/clamd.d/scan.conf/LogSyslog yes
    augtool set /files/etc/clamd.d/scan.conf/ExtendedDetectionInfo yes
    augtool set /files/etc/clamd.d/scan.conf/LocalSocket /var/run/clamd.scan/clamd.sock
    systemctl daemon-reload
    systemctl start clam-freshclam
    systemctl enable clam-freshclam.service
    sed -i 's/ = /=/g' /lib/systemd/system/clamd@.service
    augtool load
    augtool set /files/lib/systemd/system/clamd@.service/Service/RestartSec/value 30
    augtool set /files/lib/systemd/system/clamd@.service/Unit/After/value[last+1] clam-freshclam.service
    systemctl daemon-reload
    systemctl enable clamd@scan.service
    sleep 60; systemctl start clamd@scan
