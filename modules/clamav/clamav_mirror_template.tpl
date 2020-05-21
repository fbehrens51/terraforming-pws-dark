product-name: p-antivirus-mirror
product-properties:

${

no_upstream_mirror == "true" ? <<EOF

  .properties.upstream_mirror:
    selected_option: no_upstream_mirror
    value: no_upstream_mirror

EOF

:

(external_mirrors != "" ? <<EOF

  .properties.upstream_mirror:
    selected_option: external_mirror
    value: external_mirror
  .properties.upstream_mirror.external_mirror.database_mirrors:
    value: ${external_mirrors}

EOF
: <<EOF

  .properties.upstream_mirror:
    selected_option: official_mirror
    value: official_mirror

EOF
)}

  .properties.use_proxy:
    selected_option: disabled
    value: disabled
network-properties:
  network:
    name: ${bosh_network_name}
  other_availability_zones:
    ${pas_vpc_azs}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  antivirus-mirror:
    instances: automatic
    persistent_disk:
      size_mb: automatic
    instance_type:
      id: ${clamav_mirror_instance_type}
    internet_connected: false
syslog-properties:
  enabled: true
  address: ${syslog_host}
  port: ${syslog_port}
  transport_protocol: tcp
  tls_enabled: true
  ssl_ca_certificate: |
    ${indent(4, splunk_syslog_ca_cert)}
  permitted_peer: ${syslog_host}


