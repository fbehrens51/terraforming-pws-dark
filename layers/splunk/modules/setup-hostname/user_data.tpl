#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]

runcmd:
  - |
    set -ex
    hostname ${role}-`hostname`
    echo `hostname` > /etc/hostname
    sed -i 's/localhost$/localhost '`hostname`'/' /etc/hosts

