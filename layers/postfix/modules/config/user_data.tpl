#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]

users:
  - default

runcmd:
  - |
    set -ex

    echo "${smtp_pass}" | saslpasswd2 -c -u ${root_domain} ${smtp_user}
    chgrp postfix /etc/sasldb2

    postconf -e \
      "relayhost = [${smtp_relay_host}]:${smtp_relay_port}" \
      "mynetworks = ${cidr_blocks}" \
      'smtpd_helo_required=yes' \
      'inet_interfaces = all' \
      'smtp_sasl_auth_enable = yes' \
      'smtp_sasl_security_options = noanonymous' \
      'smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd' \
      'smtp_use_tls = yes' \
      'smtp_enforce_tls = yes' \
      'smtp_tls_note_starttls_offer = yes' \
      'smtp_tls_CAfile = /etc/postfix/smtp_relay_ca_cert.crt' \
      'smtp_tls_mandatory_protocols=TLSv1.2' \
      'smtp_tls_protocols=TLSv1.2' \
      'smtp_tls_loglevel = 1' \
      'smtp_tls_session_cache_database = btree:/var/lib/postfix/smtp_tls_session_cache' \
      'smtpd_tls_cert_file = /etc/postfix/smtpd_server_cert.pem' \
      'smtpd_tls_key_file = /etc/postfix/smtpd_server_key.pem'\
      'smtpd_enforce_tls = yes' \
      'smtpd_tls_auth_only = yes' \
      'smtpd_tls_mandatory_protocols=TLSv1.2' \
      'smtpd_tls_protocols=TLSv1.2' \
      'smtpd_tls_loglevel = 1' \
      'smtpd_tls_session_cache_database = btree:/var/lib/postfix/smtpd_tls_session_cache' \
      'smtpd_sasl_auth_enable = yes'

    # TODO: turn on tls
    # TODO: Do we need authentication?

    postmap hash:/etc/postfix/sasl_passwd
    chown root:root /etc/postfix/sasl_passwd.db
    chmod 0600 /etc/postfix/sasl_passwd.db

    systemctl restart postfix.service

packages:
 - postfix

write_files:
  - content: "[${smtp_relay_host}]:${smtp_relay_port} ${smtp_relay_username}:${smtp_relay_password}"
    path: /etc/postfix/sasl_passwd
    permissions: '0600'
    owner: root:root
  - content: |
      pwcheck_method: auxprop
      auxprop_plugin: sasldb
      mech_list: PLAIN LOGIN CRAM-MD5 DIGEST-MD5 NTLM
    path: /etc/sasl2/smtpd.conf
    permissions: '0600'
    owner: root:root
#  Source of postfix configuration parameters: http://www.postfix.org/postconf.5.html
