#cloud-config
write_files:
  -   content: |
        ${clam_freshclam}
      path: /usr/lib/systemd/system/clam-freshclam.service
      permissions: '0644'
      owner: root:root
runcmd:
  - sudo amazon-linux-extras install epel
  - sudo yum install clamav clamd augeas -y
  - sudo augtool set /files/etc/freshclam.conf/LogSyslog yes
  - sudo augtool set /files/etc/freshclam.conf/DatabaseMirror ${clam_database_mirror}
  - sudo augtool set /files/etc/freshclam.conf/Checks 24
  - sudo augtool rm /files/etc/clamd.d/scan.conf/Example
  - sudo augtool set /files/etc/clamd.d/scan.conf/LogSyslog yes
  - sudo augtool set /files/etc/clamd.d/scan.conf/ExtendedDetectionInfo yes
  - sudo augtool set /files/etc/clamd.d/scan.conf/LocalSocket /var/run/clamd.scan/clamd.sock
  - sudo systemctl daemon-reload
  - sudo systemctl start clam-freshclam
  - sudo systemctl enable clam-freshclam.service
  - sudo sed -i 's/ = /=/g' /lib/systemd/system/clamd@.service
  - sudo augtool load
  - sudo augtool set /files/lib/systemd/system/clamd@.service/Service/RestartSec/value 30
  - sudo augtool set /files/lib/systemd/system/clamd@.service/Unit/After/value[last+1] clam-freshclam.service
  - sudo systemctl daemon-reload
  - sudo systemctl enable clamd@scan.service
  - sleep 60; sudo systemctl start clamd@scan