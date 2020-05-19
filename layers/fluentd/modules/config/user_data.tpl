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
    while [ ! -e /dev/sdf ] ; do echo "Waiting for device /dev/sdf"; sleep 1 ; done
    if [ "$(file -b -s -L /dev/sdf)" == "data" ]; then mkfs -t ext4 /dev/sdf; fi

mounts:
  - [ "/dev/sdf", "/opt", "ext4", "defaults,nofail", "0", "2" ]

runcmd:
  - |
    set -ex

    export AWS_DEFAULT_REGION=${region}

    tmpdir=$(mktemp -d)

    aws s3 cp --no-progress s3://${public_bucket_name}/fluentd-bundle/${fluentd_bundle_key} $${tmpdir}/

    pushd $${tmpdir}
      unzip *.zip

      rpm -iv td-agent-*.rpm

      td-agent-gem install -l aws-sdk-cloudwatchlogs-*.gem
      td-agent-gem install -l fluent-plugin-cloudwatch-logs-*.gem
      td-agent-gem install -l fluent-plugin-prometheus-*.gem
    popd

    mkdir -p /opt/td-agent/s3
    chown td-agent:root -R /opt/td-agent
    chown td-agent:root -R /etc/td-agent

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
      TD_AGENT_LOG_FILE=/opt/td-agent/var/log/td-agent.log
      TD_AGENT_OPTIONS="--log-rotate-size 104857600 --log-rotate-age 10"
    path: /etc/sysconfig/td-agent