#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]

write_files:
  - content: |
      ${indent(6, smtp_relay_ca_cert)}
    path: /etc/postfix/smtp_relay_ca_cert.crt
    permissions: '0600'
    owner: root:root
  - content: |
      ${indent(6, smtpd_server_cert)}
    path: /etc/postfix/smtpd_server_cert.pem
    permissions: '0600'
    owner: root:root
  - content: |
      ${indent(6, smtpd_server_key)}
    path: /etc/postfix/smtpd_server_key.pem
    permissions: '0600'
    owner: root:root
