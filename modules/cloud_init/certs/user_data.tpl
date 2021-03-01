#cloud-config
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]
write_files:
- path: /run/certs.crt
  content: |
    ${chomp(indent(4, ca_chain))}
runcmd:
  - |
    set -ex

    echo "deleting system certificates"
    chmod 644 /usr/share/pki/ca-trust-source/ca-bundle.trust.p11-kit
    : > /usr/share/pki/ca-trust-source/ca-bundle.trust.p11-kit

    # Split files on '----END CERTIFICATE-----' and increment our file counter by 1
    awk -v n=1 '
      split_after == 1 {n++;split_after=0}
      /-----END CERTIFICATE-----/ {split_after=1}
      NF {print > "/etc/pki/ca-trust/source/anchors/cloud_init_ca_cert_" n ".crt"}' < /run/certs.crt

    /bin/update-ca-trust extract
