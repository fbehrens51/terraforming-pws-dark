product-name: p_spring-cloud-gateway-service
product-properties:
  .properties.allow_paid_service_plans:
    value: false
  .properties.apply_open_security_group:
    value: false
  .properties.java_buildpack:
    value: ${java_buildpack}
  .properties.observability_metrics_wavefront_enabled:
    value: false
  .properties.observability_tracing_wavefront_enabled:
    value: false
  .properties.org:
    value: p-spring-cloud-gateway-service
  .properties.scg_service_access:
    value: global
  .properties.space:
    value: p-spring-cloud-gateway-service
  .properties.status_change_timeout_minutes:
    value: 30
network-properties:
  network:
    name: ${network_name}
  other_availability_zones: ${az_yaml}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  spring-cloud-gateway-service:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.spring-gateway}
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