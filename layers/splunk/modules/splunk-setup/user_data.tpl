#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]

bootcmd:
  - mkdir -p /opt/splunk
  - while [ ! -e /dev/xvdf ] ; do sleep 1 ; done
  - if [ "$(file -b -s /dev/xvdf)" == "data" ]; then mkfs -t ext4 /dev/xvdf; fi

mounts:
  - [ "/dev/xvdf", "/opt/splunk", "ext4", "defaults,nofail", "0", "2" ]

runcmd:
  - |
    set -ex
    mkdir -p /opt/splunk
    aws s3 cp s3://${splunk_rpm_s3_bucket}/ . --recursive --exclude='*' --include='splunk-${splunk_rpm_version}*' --region ${splunk_rpm_s3_region}
    sudo rpm -i splunk-${splunk_rpm_version}*.rpm

    /opt/splunk/bin/splunk enable boot-start -systemd-managed 1 --no-prompt --accept-license --answer-yes

    # https://docs.splunk.com/Documentation/Splunk/7.3.1/Admin/RunSplunkassystemdservice#Configure_systemd_using_enable_boot-start
    cat <<EOF >> /etc/systemd/system/Splunkd.service
    [Service]
    KillMode=mixed
    KillSignal=SIGINT
    TimeoutStopSec=10min
    EOF
    systemctl daemon-reload

    /opt/splunk/bin/splunk start
    /opt/splunk/bin/splunk cmd splunkd rest --noauth POST /services/authentication/users "name=admin&password=${admin_password}&roles=admin"
    /opt/splunk/bin/splunk restart

