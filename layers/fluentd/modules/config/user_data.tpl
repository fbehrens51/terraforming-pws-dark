#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]

users:
  - default

# bootcmdt:
#   - |
#     mkdir -p /opt
#     while [ ! -e /dev/sdf ] ; do echo "Waiting for device /dev/sdf"; sleep 1 ; done
#     if [ "$(file -b -s /dev/sdf)" == "data" ]; then mkfs -t ext4 /dev/sdf; fi

# mounts:
#   - [ "/dev/sdf", "/opt", "ext4", "defaults,nofail", "0", "2" ]

runcmd:
  - |
    set -ex

    wget http://packages.treasuredata.com.s3.amazonaws.com/3/redhat/7/x86_64/td-agent-3.6.0-0.el7.x86_64.rpm
    rpm -iv td-agent-3.6.0-0.el7.x86_64.rpm
    td-agent-gem install fluent-plugin-splunk-enterprise
    td-agent-gem install fluent-plugin-cloudwatch-logs

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
