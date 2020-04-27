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

    wget http://packages.treasuredata.com.s3.amazonaws.com/3/redhat/7/x86_64/td-agent-3.6.0-0.el7.x86_64.rpm
    wget https://rubygems.org/downloads/fluent-plugin-splunk-enterprise-0.10.2.gem
    wget https://rubygems.org/downloads/aws-sdk-cloudwatchlogs-1.29.0.gem
    wget https://rubygems.org/downloads/fluent-plugin-cloudwatch-logs-0.5.0.gem

    rpm -iv td-agent-3.6.0-0.el7.x86_64.rpm

    td-agent-gem install -l fluent-plugin-splunk-enterprise-0.10.2.gem
    td-agent-gem install -l aws-sdk-cloudwatchlogs-1.29.0.gem
    td-agent-gem install -l fluent-plugin-cloudwatch-logs-0.5.0.gem

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
