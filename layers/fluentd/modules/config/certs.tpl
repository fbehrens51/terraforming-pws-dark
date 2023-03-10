#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
  - content: |
      ${indent(6, ca_cert)}
    path: /etc/td-agent/ca.pem
    permissions: '0600'
    owner: root:root
  - content: |
      ${indent(6, server_cert)}
    path: /etc/td-agent/cert.pem
    permissions: '0600'
    owner: root:root
  - content: |
      ${indent(6, server_key)}
    path: /etc/td-agent/key.pem
    permissions: '0600'
    owner: root:root
%{if loki_config.enabled ~}
  - content: |
      ${indent(6, loki_config.loki_client_cert)}
    path: /etc/td-agent/loki-client-cert.pem
    permissions: '0600'
    owner: root:root
  - content: |
      ${indent(6, loki_config.loki_client_key)}
    path: /etc/td-agent/loki-client-key.pem
    permissions: '0600'
    owner: root:root
%{~ endif}