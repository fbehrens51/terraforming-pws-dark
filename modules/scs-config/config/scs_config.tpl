product-name: p_spring-cloud-services
product-properties:
  .properties.allow_paid_service_plans:
    value: false
  .properties.apply_open_security_group:
    value: false
  .properties.concurrent_service_instance_upgrade:
    value: 5
  .properties.config_server_access:
    value: global
  .properties.config_server_credhub_enabled:
    value: true
  .properties.java_buildpack:
    value: java_buildpack_offline
  .properties.org:
    value: p-spring-cloud-services
  .properties.service_completion_timeout_minutes:
    value: 30
  .properties.service_key_access:
    value: false
  .properties.service_registry_access:
    value: global
  .properties.space:
    value: p-spring-cloud-services
network-properties:
  network:
    name: ${network_name}
  other_availability_zones: ${az_yaml}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  spring-cloud-services:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.spring-cloud-services}
    instances: automatic
    internet_connected: false
    persistent_disk:
      size_mb: automatic
    swap_as_percent_of_memory_size: automatic
errand-config:
  destroy-brokers:
    pre-delete-state: true
  register-brokers:
    post-deploy-state: true
  upgrade-all-instances:
    post-deploy-state: false
syslog-properties:
  address: ${syslog_host}
  custom_rsyslog_configuration: null
  enabled: true
  forward_debug_logs: false
  permitted_peer: ${syslog_host}
  port: ${syslog_port}
  queue_size: null
  ssl_ca_certificate: |-
    ${indent(4, chomp(syslog_ca_cert))}
  tls_enabled: true
  transport_protocol: tcp
