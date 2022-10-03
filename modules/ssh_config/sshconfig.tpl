%{ for host, ip in ssh_host_ips ~}
Host ${host}
   Hostname ${ip}
%{ if custom_ssh_key != "" ~}
   IdentityFile ${ssh_key_path}/${custom_ssh_key}
   IdentitiesOnly yes
%{ endif ~}
%{ if ssh_user != "" ~}
   User ${ssh_user}
%{ endif ~}
%{ if proxy_jump != "" ~}
   ProxyJump ${proxy_jump}
%{ endif ~}

%{ endfor ~}
%{ if include_base_config == true ~}
%{ if enable_sjb_proxyjump == true ~}
Host ${foundation_name}_* !*bosh !*sjb !*bastion
   ProxyJump ${sjb_name}

%{ endif ~}
Host ${foundation_name}_*
   LogLevel ERROR
   ForwardAgent yes
   ConnectTimeout 10
   StrictHostKeyChecking no
   #   User bot
   #   IdentityFile ${ssh_key_path}/${foundation_name}_bot_key.pem
   # edit
   GSSAPIAuthentication no
   UserKnownHostsFile /dev/null

Host ${foundation_name}_* !*bosh
   User <USER>
%{ endif ~}