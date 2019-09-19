#cloud-config
write_files:
  -   content: |
        ${aug_lens}
      path: /usr/share/augeas/lenses/dist/clamavubuntu.aug
      permissions: '0644'
      owner: root:root
runcmd:
  - mkdir pkg
  - cd pkg
  - wget --no-check-certificate -O - "${deb_tgz_location}" | tar xzf -
  - sudo dpkg -i *.deb
  - sudo rm -f *.deb
  - sudo augtool set /files/etc/clamav/freshclam.conf/LogSyslog yes
  - sudo augtool set /files/etc/clamav/freshclam.conf/DatabaseMirror[2] ${clam_database_mirror}
  - sudo augtool set /files/etc/clamav/freshclam.conf/Checks 24
  - sudo augtool rm /files/etc/clamav/scan.conf/Example
  - sudo augtool set /files/etc/clamav/scan.conf/LogSyslog yes
  - sudo augtool set /files/etc/clamav/scan.conf/ExtendedDetectionInfo yes
  - sudo augtool set /files/etc/clamav/scan.conf/LocalSocket /var/run/clamd.scan/clamd.sock
  - sudo systemctl daemon-reload
  - sudo systemctl start clamav-freshclam.service
  - sudo systemctl enable clamav-freshclam.service
  - sudo augtool load
  - sudo augtool set /files/lib/systemd/system/clamav-daemon.service/Service/RestartSec/value 30
  - sudo augtool set /files/lib/systemd/system/clamav-daemon.service/Unit/After/value[last+1] clamav-freshclam.service
  - sudo systemctl daemon-reload
  - sudo systemctl enable clamav-daemon.service
  - sleep 60; sudo systemctl start clamav-daemon.service