%{ for host, ip in ssh_host_ips ~}
Host ${host}
   Hostname ${ip}

%{ endfor ~}

Host ${bosh_name}
   Hostname ${bosh_ip}
   IdentityFile ${ssh_key_path}/${foundation_name}_bbr_key.pem
   ProxyJump ${om_name}

