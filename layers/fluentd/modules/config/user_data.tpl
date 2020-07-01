#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]

users:
  - default

bootcmd:
  - |
    set -ex
    mkdir -p /opt
    mkdir -p /data
    while [ ! -e /dev/sdf ] ; do echo "Waiting for device /dev/sdf"; sleep 1 ; done
    if [ "$(file -b -s -L /dev/sdf)" == "data" ]; then mkfs -t ext4 /dev/sdf; fi

mounts:
  - [ "/dev/sdf", "/data", "ext4", "defaults,nofail", "0", "2" ]

runcmd:
  - |
    set -exo pipefail

    export AWS_DEFAULT_REGION=${region}

    tmpdir=$(mktemp -d)

    aws s3 cp --no-progress s3://${public_bucket_name}/fluentd-bundle/${fluentd_bundle_key} $${tmpdir}/

    pushd $${tmpdir}
      unzip *.zip

      rpm -iv td-agent-*.rpm

      td-agent-gem install -l *.gem

      gems=$(ls -1 *.gem | grep -Po '^(.*)(?=-[\d+\.]+.gem)' | paste -sd ' ')
      lines=$(td-agent-gem check $${gems} | wc -l )
      if [ $${lines} -gt 2 ]; then
        echo "dependency checked failed for $${gems}, exiting"
        td-agent-gem check $${gems}
        exit 1
      fi

    popd

    mkdir -p /data/s3 /data/log /data/audispd
    chown td-agent:root -R /opt/td-agent /etc/td-agent /data/s3 /data/audispd /data/log

    systemctl enable td-agent
    systemctl start td-agent

packages:
- redhat-lsb-core

write_files:
  - content: |
      ${indent(6, td_agent_configuration)}
    path: /etc/td-agent/td-agent.conf
    permissions: '0644'
    owner: root:root
  - content: |
      TD_AGENT_LOG_FILE=/data/log/td-agent.log
      TD_AGENT_OPTIONS="--log-rotate-size 104857600 --log-rotate-age 10"
    path: /etc/sysconfig/td-agent
