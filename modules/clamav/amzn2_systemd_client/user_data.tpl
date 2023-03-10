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
  - content: |
      20 04 * * * root clamscan -ir / --exclude-dir=/sys/ --exclude-dir=/proc/ --exclude-dir=/opt/rapid7/ --stdout | logger -i -t antivirus -p auth.alert
    path: /etc/cron.d/antivirus
    permissions: '0644'
    owner: root:root
runcmd:
  - |
    set -ex
    mkdir pkg
    pushd pkg
    wget -q --no-check-certificate -O - "${clamav_rpms_pkg_object_url}" | tar xzf -
    yum localinstall * -y
    popd
    rm -rf pkg
    # give clamupdate user a new home dir with restricted perms.
    # leave existing /var/lib/clamav world readable.
    install -m750 -o clamupdate -g clamupdate -d /var/lib/clamupdate
    usermod -d /var/lib/clamupdate clamupdate
    # Next two lines fix the perms as installed by the rpm, and then during logrotation
    chmod 660 /var/log/freshclam.log
    augtool set /files/etc/logrotate.d/clamav-update/rule/create/mode 660
    augtool set /files/etc/freshclam.conf/LogSyslog yes
    augtool rm /files/etc/freshclam.conf/DNSDatabaseInfo
    augtool set /files/etc/freshclam.conf/DNSDatabaseInfo disabled
    augtool rm /files/etc/freshclam.conf/DatabaseMirror
    augtool set /files/etc/freshclam.conf/PrivateMirror ${clam_database_mirror}
    augtool set /files/etc/freshclam.conf/Checks 24
    augtool rm /files/etc/clamd.d/scan.conf/Example
    augtool set /files/etc/clamd.d/scan.conf/LogSyslog yes
    augtool set /files/etc/clamd.d/scan.conf/ExtendedDetectionInfo yes
    augtool set /files/etc/clamd.d/scan.conf/LocalSocket /var/run/clamd.scan/clamd.sock
    augtool set /files/etc/clamd.d/scan.conf/ExcludePath ^/opt/rapid7/
    systemctl daemon-reload
    systemctl start clam-freshclam
    systemctl enable clam-freshclam.service
    sed -i 's/ = /=/g' /lib/systemd/system/clamd@.service
    augtool load
    augtool set /files/lib/systemd/system/clamd@.service/Service/RestartSec/value 30
    augtool set /files/lib/systemd/system/clamd@.service/Unit/After/value[last+1] clam-freshclam.service
    systemctl daemon-reload
    systemctl enable clamd@scan.service
    # clamd@scan can take a long time to start,
    # so we don't wait for it to finish here.
    systemctl start clamd@scan --no-block
