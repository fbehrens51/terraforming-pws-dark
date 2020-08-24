product-name: metric-store
network-properties:
  network:
    name: ${bosh_network_name}
  other_availability_zones:
    ${indent(4, chomp(pas_vpc_azs))}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  metric-store:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: automatic
    instances: automatic
    internet_connected: false
    persistent_disk:
      size_mb: automatic
    swap_as_percent_of_memory_size: automatic
errand-config:
  metric-store-smoke-tests:
    post-deploy-state: true
syslog-properties:
  address: ${syslog_host}
  custom_rsyslog_configuration: null
  enabled: true
  forward_debug_logs: false
  permitted_peer: ${syslog_host}
  port: ${syslog_port}
  queue_size: null
  ssl_ca_certificate: |
    ${indent(4, chomp(syslog_ca_cert))}
  tls_enabled: true
  transport_protocol: tc
