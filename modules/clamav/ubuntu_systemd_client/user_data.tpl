#cloud-config
write_files:
  -   content: |
        ${aug_lens}
      path: /usr/share/augeas/lenses/dist/clamavubuntu.aug
      permissions: '0644'
      owner: root:root
  - content: |
      20 04 * * * root clamscan -ir / --exclude-dir=/sys/ --exclude-dir=/proc/ --stdout | logger -i -t antivirus -p auth.alert
    path: /etc/cron.d/antivirus
    permissions: '0644'
    owner: root:root
runcmd:
  - |
    set -ex
    mkdir pkg
    cd ./pkg
    wget -q --no-check-certificate -O - "${deb_tgz_location}" | tar xzf -
    dpkg -i *.deb
    cd ..
    rm -rf pkg
    augtool set /files/etc/clamav/freshclam.conf/LogSyslog yes
    augtool rm /files/etc/clamav/freshclam.conf/DNSDatabaseInfo
    augtool set /files/etc/clamav/freshclam.conf/DNSDatabaseInfo disabled
    augtool rm /files/etc/clamav/freshclam.conf/DatabaseMirror
    augtool set /files/etc/clamav/freshclam.conf/PrivateMirror ${clam_database_mirror}
    augtool set /files/etc/clamav/freshclam.conf/Checks 24
    augtool rm /files/etc/clamav/scan.conf/Example
    augtool set /files/etc/clamav/scan.conf/LogSyslog yes
    augtool set /files/etc/clamav/scan.conf/ExtendedDetectionInfo yes
    augtool set /files/etc/clamav/scan.conf/LocalSocket /var/run/clamd.scan/clamd.sock
    augtool load
    augtool set /files/lib/systemd/system/clamav-daemon.service/Service/RestartSec/value 30
    augtool set /files/lib/systemd/system/clamav-daemon.service/Unit/After/value[last+1] clamav-freshclam.service
    sudo -u clamav freshclam
    systemctl daemon-reload
    systemctl enable clamav-daemon.service
    systemctl enable clamav-freshclam.service
    systemctl restart clamav-freshclam.service
    systemctl restart clamav-daemon.service
