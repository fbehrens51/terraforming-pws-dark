%{ for host, ip in ssh_host_ips ~}
Host ${host}
   Hostname ${ip}

%{ endfor ~}

Host ${cp_bosh_name}
   Hostname ${cp_bosh_ip}
   IdentityFile ${ssh_key_path}/${foundation_name}_cp_bbr_key.pem
   ProxyJump ${cp_om_name}
