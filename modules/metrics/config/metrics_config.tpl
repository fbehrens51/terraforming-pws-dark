product-name: appMetrics
product-properties:
  .db-and-errand-runner.enable_logs:
    value: true
  .db-and-errand-runner.use_socks_proxy:
    value: false
  .log-store-vms.log_store_prune_interval:
    value: 2m
  .log-store-vms.log_store_prune_threshold:
    value: 80
network-properties:
  network:
    name: ${bosh_network_name}
  other_availability_zones:
    ${indent(4, chomp(pas_vpc_azs))}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  db-and-errand-runner:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.db-and-errand-runner}
    instances: automatic
    internet_connected: false
    persistent_disk:
      size_mb: automatic
    swap_as_percent_of_memory_size: automatic
  log-store-vms:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.log-store-vms}
    instances: automatic
    internet_connected: false
    persistent_disk:
      size_mb: automatic
    swap_as_percent_of_memory_size: automatic
errand-config:
  delete-space:
    pre-delete-state: true
  migrate-route:
    post-deploy-state: false
  push-app-metrics:
    post-deploy-state: true
  smoke-test:
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
  transport_protocol: tcp
