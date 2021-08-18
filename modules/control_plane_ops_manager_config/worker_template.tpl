product-name: pws-dark-concourse-worker-tile
syslog-properties:
  enabled: true
  address: ${syslog_host}
  port: ${syslog_port}
  transport_protocol: tcp
  tls_enabled: true
  ssl_ca_certificate: |
    ${indent(4, chomp(syslog_ca_cert))}
  permitted_peer: ${syslog_host}
product-properties:
  .properties.tags:
    value:
    - tag_name: external
network-properties:
  network:
    name: control-plane-subnet
  other_availability_zones:
    ${chomp(control_plane_vpc_azs)}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  worker:
    instances: automatic
    instance_type:
      id: ${scale.worker}
    internet_connected: false
    additional_vm_extensions:
    - worker_instance_profile

