#cloud-config
packages:
  - dnsmasq
  - bind-utils

# create dnsmasq user
users:
  - default
  - name: dnsmasq
    inactive: true
    system: true
    shell: /sbin/nologin
    lock_passwd: true

runcmd:
  # Start dnsmask service and enable it to start at every reboot
  - pidof systemd && systemctl restart dnsmasq.service || service dnsmasq restart
  - pidof systemd && systemctl enable  dnsmasq.service || chkconfig dnsmasq on

  # Configure /etc/dhcp/dhclient.conf and /etc/resolv.dnsmasq with the right DNS IP Address
  - bash -c "echo 'supersede domain-name-servers 127.0.0.1%{for server in enterprise_dns}, ${server}%{endfor};' >> /etc/dhcp/dhclient.conf && echo -e \"%{for server in enterprise_dns}nameserver ${server}\n%{endfor}\" > /etc/resolv.dnsmasq && chmod 644 /etc/resolv.dnsmasq";
  # Restart network
  - systemctl restart network.service

# Configure /etc/dnsmasq.conf accordingly
write_files:
  - path: /etc/dnsmasq.conf
    permissions: '0644'
    owner: root:root
    content: |
        # Server Configuration
        listen-address=127.0.0.1
        port=53
        bind-interfaces
        user=dnsmasq
        group=dnsmasq
        pid-file=/var/run/dnsmasq.pid
        conf-dir=/etc/dnsmasq.d,.rpmnew,.rpmsave,.rpmorig
        # Name resolution options
        resolv-file=/etc/resolv.dnsmasq
        cache-size=500
        neg-ttl=60
        domain-needed
        bogus-priv
  - path: /etc/dnsmasq.d/cp.conf
    permissions: '0644'
    owner: root:root
    content: |
    %{for forwarder in forwarders ~}%{for ip in forwarder.forwarder_ips ~}
    %{if length(forwarder.domain) == 0 ~}server=${ip}%{else}server=/${forwarder.domain}/${ip}%{endif}
    %{endfor ~}%{endfor ~}
