%{ for host, ip in ssh_host_ips ~}
Host ${host}
   Hostname ${ip}

%{ endfor ~}
Host ${bastion_name}
   Hostname ${bastion_ip}

Host ${sjb_name}
   Hostname ${sjb_ip}
%{ if enable_bastion_proxyjump == true ~}
   ProxyJump ${bastion_name}
%{ endif ~}



Host ${foundation_name}*bosh
   User bbr

%{ if enable_sjb_proxyjump == true ~}
Host ${foundation_name}_* !*bosh !*sjb !*bastion
   ProxyJump ${sjb_name}

%{ endif ~}
Host ${foundation_name}_*
   LogLevel ERROR
   ConnectTimeout 10
   StrictHostKeyChecking no
#   User bot
#   IdentityFile ${ssh_key_path}/${foundation_name}_bot_key.pem
# edit
   User <USER>
   GSSAPIAuthentication no
   IdentitiesOnly yes
   UserKnownHostsFile /dev/null
