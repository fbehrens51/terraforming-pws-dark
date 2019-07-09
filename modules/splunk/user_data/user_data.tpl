#cloud-config
users:
  - default

runcmd:
  - mkdir /opt/splunk
  - while [ ! -e /dev/xvdf ] ; do sleep 1 ; done
  - if [ "$(file -b -s /dev/xvdf)" == "data" ]; then mkfs -t ext4 /dev/xvdf; fi
  - mount /dev/xvdf /opt/splunk
  - echo '/dev/xvdf  /opt/splunk ext4 defaults,nofail 0 2' >> /etc/fstab
  - aws s3 cp s3://product-blobs/ . --recursive --exclude='*' --include='splunk-7.3.0*'
  - sudo rpm -i splunk-7.3.0*.rpm
  - /opt/splunk/bin/splunk start --no-prompt --accept-license --answer-yes
  - /opt/splunk/bin/splunk cmd splunkd rest --noauth POST /services/authentication/users "name=admin&password=${password}&roles=admin"
  - /opt/splunk/bin/splunk restart