#cloud-config
write_files:
  -   content: |
        ${service_file}
      path: /etc/init.d/freshclam
      permissions: '0755'
      owner: root:root
  -   content: |
        ${aug_lens}
      path: /usr/share/augeas/lenses/dist/clamav.aug
      permissions: '0644'
      owner: root:root
runcmd:
  - sudo yum install clamav clamd augeas -y
  - sudo augtool set /files/etc/freshclam.conf/LogSyslog yes
  - sudo augtool set /files/etc/freshclam.conf/DatabaseMirror ${clam_database_mirror}
  - sudo augtool set /files/etc/freshclam.conf/Checks 24
  - sudo augtool rm /files/etc/clamd.d/scan.conf/Example
  - sudo augtool set /files/etc/clamd.d/scan.conf/LogSyslog yes
  - sudo augtool set /files/etc/clamd.d/scan.conf/ExtendedDetectionInfo yes
  - sudo augtool set /files/etc/clamd.d/scan.conf/LocalSocket /var/run/clamd.scan/clamd.sock
  - sudo service freshclam start
  - sleep 60; sudo service clamd.scan start
