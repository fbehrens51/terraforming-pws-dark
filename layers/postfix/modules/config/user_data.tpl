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

    set +x
    echo "${smtp_pass}" | saslpasswd2 -c -u ${root_domain} ${smtp_user}
    set -x
    chgrp postfix /etc/sasldb2

    postconf -e \
      header_checks=pcre:/etc/postfix/header_checks \
      inet_interfaces=all \
      mydestination=${smtp_fqdn} \
      mydomain=${root_domain} \
      myhostname="$(hostname -s).${root_domain}" \
      mynetworks="${cidr_blocks}" \
      relayhost="[${smtp_relay_host}]:${smtp_relay_port}" \
      sender_canonical_classes=envelope_sender \
      sender_canonical_maps=pcre:/etc/postfix/sender_canonical \
      smtpd_enforce_tls=yes \
      smtpd_helo_required=yes \
      smtpd_sasl_auth_enable=yes \
      smtpd_tls_auth_only=yes \
      smtpd_tls_cert_file=/etc/postfix/smtpd_server_cert.pem \
      smtpd_tls_exclude_ciphers='MD5,DES,ADH,RC4,PSD,SRP,3DES,eNULL,aNULL' \
      smtpd_tls_key_file=/etc/postfix/smtpd_server_key.pem \
      smtpd_tls_loglevel=1 \
      smtpd_tls_mandatory_ciphers=high \
      smtpd_tls_mandatory_exclude_ciphers='MD5,DES,ADH,RC4,PSD,SRP,3DES,eNULL,aNULL' \
      smtpd_tls_mandatory_protocols=TLSv1.2 \
      smtpd_tls_protocols=TLSv1.2 \
      smtpd_tls_session_cache_database=btree:/var/lib/postfix/smtpd_tls_session_cache \
      smtp_enforce_tls=yes \
      smtp_fallback_relay= \
      smtp_generic_maps=hash:/etc/postfix/generic \
      smtp_header_checks=regexp:/etc/postfix/header_checks \
      smtp_sasl_auth_enable=yes \
      smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd \
      smtp_sasl_security_options=noanonymous \
      smtp_tls_CAfile=/etc/postfix/smtp_relay_ca_cert.crt \
      smtp_tls_loglevel=1 \
      smtp_tls_mandatory_protocols=TLSv1.2 \
      smtp_tls_note_starttls_offer=yes \
      smtp_tls_protocols=TLSv1.2 \
      smtp_tls_session_cache_database=btree:/var/lib/postfix/smtp_tls_session_cache \
      smtp_use_tls=yes \
      tls_high_cipherlist=ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-GCM-SHA384 \
      tls_preempt_cipherlist=yes

    # TODO: turn on tls
    # TODO: Do we need authentication?

    echo "@$(hostname -s).${root_domain} ${smtp_from}" > /etc/postfix/generic
    postmap hash:/etc/postfix/generic
    chown root:root /etc/postfix/generic
    chmod 0644 /etc/postfix/generic

    postmap hash:/etc/postfix/sasl_passwd
    chown root:root /etc/postfix/sasl_passwd.db
    chmod 0600 /etc/postfix/sasl_passwd.db

    systemctl restart postfix.service

packages:
 - postfix
 - mailx

write_files:
  - content: |
      /From:.*/ REPLACE From: ${smtp_from}
      /To:.*/ REPLACE To: ${smtp_to}
    path: /etc/postfix/header_checks
    permissions: '0644'
    owner: root:root
  - content: |
      /From:.*/ REPLACE From: ${smtp_from}
    path: /etc/postfix/sender_canonical
    permissions: '0644'
    owner: root:root
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
