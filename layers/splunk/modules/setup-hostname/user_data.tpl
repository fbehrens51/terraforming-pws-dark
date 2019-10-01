#cloud-config
runcmd:
  - |
    set -ex
    hostname ${role}-`hostname`
    echo `hostname` > /etc/hostname
    sed -i 's/localhost$/localhost '`hostname`'/' /etc/hosts

