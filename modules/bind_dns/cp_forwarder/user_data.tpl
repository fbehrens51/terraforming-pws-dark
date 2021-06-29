#cloud-config
users:
  - default
  - name: named

runcmd:
  - |
    set -ex
    sudo echo
    mkdir -p /var/named/data
    sudo yum clean all; sudo yum install bind bind-utils -y
    sudo chkconfig --level 345 named on
    sudo mkdir /var/log/named
    sudo chown named:named /var/log/named
    sudo chmod 0700 /var/log/named
    sudo chown -R named:named /var/named/data/
    sudo systemctl restart named

write_files:
  - encoding: b64
    content: ${named_conf_content}
    path: /etc/named.conf
    permissions: '0644'


