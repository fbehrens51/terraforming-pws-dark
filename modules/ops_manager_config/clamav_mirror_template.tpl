product-name: p-clamav-mirror
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
    name: pas
  other_availability_zones:
    ${pas_vpc_azs}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  clamav-mirror:
    instances: automatic
    persistent_disk:
      size_mb: automatic
    instance_type:
      id: automatic
    internet_connected: false
