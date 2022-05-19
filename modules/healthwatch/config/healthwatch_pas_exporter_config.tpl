product-name: p-healthwatch2-pas-exporter
product-properties:
  .bosh-deployments-exporter.bosh_client:
    value:
      identity: ${bosh_client_username}
      password: ${bosh_client_password}
  .bosh-health-exporter.health_check_az:
    value: ${health_check_availability_zone}
  .bosh-health-exporter.health_check_vm_type:
    value: t3.medium
  .cert-expiration-exporter.skip_ssl_validation:
    value: false
  .pas-sli-exporter.cf_cli_version:
    value: "7"
  .properties.opsman_skip_ssl_validation:
    value: false
network-properties:
  network:
    name: ${network_name}
  other_availability_zones:
  ${hw_vpc_azs}
  service_network:
    name: ${network_name}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  bosh-deployments-exporter:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.bosh-deployments-exporter}
    instances: automatic
    internet_connected: false
    persistent_disk:
      size_mb: automatic
    swap_as_percent_of_memory_size: automatic
  bosh-health-exporter:
    max_in_flight: 2
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.bosh-health-exporter}
    instances: automatic
    internet_connected: false
    persistent_disk:
      size_mb: automatic
    swap_as_percent_of_memory_size: automatic
  cert-expiration-exporter:
    max_in_flight: 5
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.cert-expiration-exporter}
    instances: automatic
    internet_connected: false
    persistent_disk:
      size_mb: automatic
    swap_as_percent_of_memory_size: automatic
  pas-exporter-counter:
    max_in_flight: 5
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.pas-exporter-counter}
    instances: automatic
    internet_connected: false
    persistent_disk:
      size_mb: automatic
    swap_as_percent_of_memory_size: automatic
  pas-exporter-gauge:
    max_in_flight: 5
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.pas-exporter-gauge}
    instances: automatic
    internet_connected: false
    persistent_disk:
      size_mb: automatic
    swap_as_percent_of_memory_size: automatic
  pas-sli-exporter:
    max_in_flight: 2
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.pas-sli-exporter}
    instances: automatic
    internet_connected: false
    persistent_disk:
      size_mb: automatic
    swap_as_percent_of_memory_size: automatic
  svm-forwarder:
    max_in_flight: 5
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: t3.medium
    instances: automatic
    internet_connected: false
    persistent_disk:
      size_mb: automatic
    swap_as_percent_of_memory_size: automatic
errand-config:
  bosh-cleanup-wait:
    pre-delete-state: true
  delete-cf-sli-user:
    pre-delete-state: true
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
    ${indent(4, syslog_ca_cert)}
  tls_enabled: true
  transport_protocol: tcp
