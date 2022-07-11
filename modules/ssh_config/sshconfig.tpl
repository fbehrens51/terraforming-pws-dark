%{ for host, ip in ssh_host_ips ~}
Host ${host}
   Hostname ${ip}
%{ if custom_ssh_key != "" ~}
   IdentityFile ${ssh_key_path}/${custom_ssh_key}
%{ endif ~}
%{ if ssh_user != "" ~}
   User ${ssh_user}
%{ endif ~}
%{ if proxy_jump != "" ~}
   ProxyJump ${proxy_jump}
%{ endif ~}

%{ endfor ~}
%{ if enable_sjb_proxyjump == true ~}
Host ${foundation_name}_* !*bosh !*sjb !*bastion
   ProxyJump ${sjb_name}
%{ endif ~}

%{ if include_base_config == true ~}
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
%{ endif ~}