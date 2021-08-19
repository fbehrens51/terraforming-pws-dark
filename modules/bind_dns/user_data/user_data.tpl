#cloud-config
users:
  - default
  - name: named

runcmd:
  - |
    set -ex
    mkdir -p /var/named/data
    mv /run/${zone_file_name} /var/named/data/${zone_file_name}
    sudo yum clean all; sudo yum install bind bind-utils -y
    sudo chkconfig --level 345 named on
    sudo mkdir /var/log/named
    sudo chown named:named /var/log/named
    sudo chmod 0700 /var/log/named
    sudo chown named:named /var/named/data/*
    sudo systemctl restart named

write_files:
  - encoding: b64
    content: ${named_conf_content}
    path: /etc/named.conf
    permissions: '0644'
  - encoding: b64
    content: ${zone_content}
    path: /run/${zone_file_name}
    permissions: '0644'
  - encoding: b64
    content: ${named_conf_systemd}
    path: /etc/sysconfig/named
    permissions: '0644'
