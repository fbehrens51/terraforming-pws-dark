product-name: apmPostgres
product-properties:
  .errand-runner.ingestor_instance_count:
    value: 1
  .errand-runner.logs_queue_instance_count:
    value: 1
  .errand-runner.logs_queue_max_retention_percentage:
    value: 85
  .errand-runner.logs_queue_retention_percentage_interval:
    value: 1h
  .errand-runner.logs_retention_window:
    value: 14
  .errand-runner.metrics_queue_instance_count:
    value: 1
  .errand-runner.metrics_retention_window:
    value: 14
  .errand-runner.push_apps_log_level:
    value: error
  .errand-runner.server_instance_count:
    value: 1
network-properties:
  network:
    name: ${bosh_network_name}
  other_availability_zones:
    ${pas_vpc_azs}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  errand-runner:
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
  mysql:
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
  postgres:
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
  redis:
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
  delete-prior-space:
    post-deploy-state: true
  delete-space:
    pre-delete-state: true
  migrate-route:
    post-deploy-state: true
  push-apps:
    post-deploy-state: true
  smoke-tests:
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
    ${indent(4, splunk_syslog_ca_cert)}
  tls_enabled: true
  transport_protocol: tcp
