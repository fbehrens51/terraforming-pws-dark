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
