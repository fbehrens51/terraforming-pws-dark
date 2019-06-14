#cloud-config
users:
  - default
  - name: named

runcmd:
  - sudo yum update -y
  - sudo yum install bind bind-utils -y
  - sudo chkconfig --level 345 named on
  - sudo iptables -A INPUT -s 0.0.0.0/0 -p tcp -m state --state NEW --dport 53 -j ACCEPT
  - sudo iptables -A INPUT -s 0.0.0.0/0 -p udp -m state --state NEW --dport 53 -j ACCEPT
  - sudo mkdir /var/log/named
  - sudo chown named:named /var/log/named
  - sudo chmod 0700 /var/log/named
  - sudo chown named:named /var/named/data/*
  - sudo chown root:named /etc/rndc.key
  - sudo /sbin/service named stop
  - sudo /sbin/service named start

write_files:
  - encoding: b64
    content: ${named_conf_content}
    path: /etc/named.conf
    permissions: '0644'
  - encoding: b64
    content: ${zone_content}
    path: /var/named/data/${zone_file_name}
    permissions: '0644'
  - encoding: b64
    content: ${reverse_content}
    path: /var/named/data/${reverse_file_name}
    permissions: '0644'
  - encoding: b64
    content: ${rndc_content}
    path: /etc/rndc.key
    permissions: '0640'
