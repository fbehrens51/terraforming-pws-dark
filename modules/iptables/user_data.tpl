#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]
runcmd:
  - |
    %{~ for cidr in control_plane_subnet_cidrs ~}
    iptables -I INPUT -s "${cidr}" -j ACCEPT
    %{~ endfor ~}
    %{~ if nat ~}
    iptables -t nat -F
    %{~ endif ~}
    iptables -F

    iptables -P INPUT   DROP
    iptables -P OUTPUT  DROP
    iptables -P FORWARD DROP
    %{~ if nat }
    # Enable NAT traffic
    iptables -A FORWARD -o eth0 -j ACCEPT
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    %{~ endif ~}

    # Ensure loopback traffic is configured
    iptables -A INPUT  -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    iptables -A INPUT  -s 127.0.0.0/8 -j DROP

    # Housekeeping
    iptables -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
    iptables -A INPUT -f -j DROP
    iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
    iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
    iptables -A INPUT -p icmp --icmp-type address-mask-request -j DROP
    iptables -A INPUT -p icmp --icmp-type timestamp-request -j DROP
    iptables -A INPUT -p icmp --icmp-type router-solicitation -j DROP

    %{~ for ior in internet_only_rules ~}
    ${ior}
    %{~ endfor}
    # Ensure outbound and established connections are configured
    iptables -A OUTPUT -p tcp  -m state --state NEW,ESTABLISHED -j ACCEPT
    iptables -A OUTPUT -p udp  -m state --state NEW,ESTABLISHED -j ACCEPT
    iptables -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT
    iptables -A INPUT  -p tcp  -m state --state ESTABLISHED -j ACCEPT
    iptables -A INPUT  -p udp  -m state --state ESTABLISHED -j ACCEPT
    iptables -A INPUT  -p icmp -m state --state ESTABLISHED -j ACCEPT

    # Open inbound ssh(tcp port 22) connections
    iptables -A INPUT -p tcp --dport 22 -m state --state NEW -j ACCEPT
    iptables -A INPUT -p tcp --dport 9100 -m state --state NEW -j ACCEPT
    iptables -A INPUT -p udp --dport 67:68 --sport 67:68 -m state --state NEW -j ACCEPT
    %{~ for pr in personality_rules ~}
    ${pr}
    %{~ endfor ~}

    # anything left on the input chain will be logged.
    if ! iptables -L LOGGING 2> /dev/null; then
      iptables -N LOGGING
    fi
    iptables -A INPUT -j LOGGING
    iptables -A LOGGING -j LOG --log-prefix "IPTables Packet Dropped: " --log-level 4
    iptables -A LOGGING -j DROP

    iptables-save -f /etc/sysconfig/iptables
