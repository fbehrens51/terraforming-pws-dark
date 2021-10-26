%{ for host, ip in ssh_host_ips ~}
Host ${host}
   Hostname ${ip}

%{ endfor ~}
Host ${bastion_name}
   Hostname ${bastion_ip}

Host ${sjb_name}
   Hostname ${sjb_ip}
%{ if enable_proxyjump == true ~}
   ProxyJump ${bastion_name}
%{ endif ~}

Host ${bosh_name}
   Hostname ${bosh_ip}
# edit
   IdentityFile ${ssh_key_path}/${foundation_name}_bbr_key.pem
   ProxyJump ${om_name}

Host ${cp_bosh_name}
   Hostname ${cp_bosh_ip}
# edit
   IdentityFile ${ssh_key_path}/${foundation_name}_cp_bbr_key.pem
   ProxyJump ${cp_om_name}

Host ${foundation_name}*bosh
   User bbr

%{ if enable_proxyjump == true ~}
Host ${foundation_name}_* !*bosh !*sjb !*bastion
   ProxyJump ${sjb_name}

%{ endif ~}
Host ${foundation_name}_*
   LogLevel ERROR
   ConnectTimeout 10
   StrictHostKeyChecking no
%{ if enable_bot_user == true ~}
   User bot
# edit
   IdentityFile ${ssh_key_path}/${foundation_name}_bot_key.pem
%{ else ~}
# edit
   User <USER>
%{ endif ~}
   GSSAPIAuthentication no
   IdentitiesOnly yes
   UserKnownHostsFile /dev/null
