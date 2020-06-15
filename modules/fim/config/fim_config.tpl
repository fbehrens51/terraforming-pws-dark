product-name: p-fim
product-properties:
  .properties.bosh_context_adaptor:
    selected_option: enabled
    value: enabled
  .properties.cache:
    selected_option: disabled
    value: disabled
  .properties.cpu_limit:
    value: 10
  .properties.digests:
    selected_option: disabled
    value: disabled
  .properties.digests_for_windows:
    selected_option: disabled
    value: disabled
  .properties.dirs:
    value:
    - path: /boot/grub
    - path: /root
    - path: /bin
    - path: /etc
    - path: /lib
    - path: /lib64
    - path: /opt
    - path: /sbin
    - path: /srv
    - path: /usr
    - path: /var/lib
    - path: /var/vcap/bosh
    - path: /var/vcap/monit/job
    - path: /var/vcap/data/packages
    - path: /var/vcap/data/jobs
  .properties.enforce_cpu_limit:
    selected_option: disabled
    value: disabled
  .properties.format:
    value: CEF:0|cloud_foundry|fim|1.0.0|{{.OpType}}|file integrity monitoring event|{{.Severity}}| {{.KeyValues}}
  .properties.format_for_windows:
    value: CEF:0|cloud_foundry|fim|1.0.0|{{.OpType}}|file integrity monitoring event|{{.Severity}}| {{.KeyValues}}
  .properties.heartbeat_interval:
    value: 600
  .properties.heartbeat_interval_for_windows:
    value: 600
  .properties.ignored_patterns:
    value:
    - regex: ^/etc/passwd.+$
    - regex: ^/etc/shadow.+$
    - regex: ^/etc/subgid.+$
    - regex: ^/etc/subuid.+$
    - regex: ^/etc/group.+$
    - regex: ^/etc/gshadow.+$
    - regex: ^/etc/hosts.+$
    - regex: ^/var/vcap/bosh/log/.+$
    - regex: ^/var/lib/logrotate/status.*$
    - regex: ^/root/\.monit\.state$
  .properties.low_severity_patterns:
    value:
    - regex: ^/etc/passwd$
    - regex: ^/etc/shadow$
    - regex: ^/etc/subgid$
    - regex: ^/etc/subuid$
    - regex: ^/etc/group$
    - regex: ^/etc/gshadow$
    - regex: ^/etc/hosts$
    - regex: ^/etc/mtab$
    - regex: ^/var/lib/dhcp/dhclient.eth\d+.leases$
    - regex: ^/var/vcap/bosh/settings.json$
    - regex: ^/var/vcap/data/jobs$
    - regex: ^/var/vcap/data/packages$
  .properties.memory_limit:
    value: 536870912
  .properties.windows_dirs:
    value:
    - path: C:\Windows\System32
    - path: C:\Program Files
    - path: C:\Program Files (x86)
    - path: C:\var\vcap\bosh
    - path: C:\var\vcap\data\packages
    - path: C:\var\vcap\data\jobs

