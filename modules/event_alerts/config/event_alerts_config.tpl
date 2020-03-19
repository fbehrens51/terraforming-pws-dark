product-name: p-event-alerts
product-properties:
  .deploy-pcf-event-alerts.instance_count:
    value: 5
  .deploy-pcf-event-alerts.metrics_forwarder_enabled:
    value: true
  .properties.mysql:
    selected_option: external
    value: External DB
  .properties.mysql.external.database:
    value: ${mysql_name}
  .properties.mysql.external.host:
    value: ${mysql_host}
  .properties.mysql.external.password:
    value:
      secret: ${mysql_password}
  .properties.mysql.external.port:
    value: ${mysql_port}
%{ if mysql_use_tls == "true" ~}
  .properties.mysql.external.server_ca:
    value: |
      ${mysql_ca_cert}
  .properties.mysql.external.skip_ssl_validation:
    value: ${mysql_tls_skip_verify}
%{ endif ~}
  .properties.mysql.external.use_tls:
    value: ${mysql_use_tls}
  .properties.mysql.external.username:
    value: ${mysql_username}
  .properties.smtp_selector:
%{ if smtp_enabled == "false" ~}
    selected_option: disabled
    value: Disabled
%{ else ~}
    selected_option: enabled
    value: Enabled
  .properties.smtp_selector.enabled.smtp_address:
    value: ${smtp_host}
  .properties.smtp_selector.enabled.smtp_credentials:
    value:
      identity: ${smtp_username}
      password: ${smtp_password}
  .properties.smtp_selector.enabled.smtp_from:
    value: ${smtp_from}
  .properties.smtp_selector.enabled.smtp_insecure_skip_verify:
    value: ${smtp_tls_skip_verify}
  .properties.smtp_selector.enabled.smtp_port:
    value: ${smtp_port}
  .properties.smtp_selector.enabled.smtp_tls_enabled:
    value: ${smtp_tls_enabled}
%{ endif ~}
network-properties:
  network:
    name: ${bosh_network_name}
  other_availability_zones:
    ${pas_vpc_azs}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  deploy-pcf-event-alerts:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: automatic
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
  destroy-pcf-event-alerts:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: automatic
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
errand-config:
  deploy-pcf-event-alerts:
    post-deploy-state: when-changed
  destroy-pcf-event-alerts:
    pre-delete-state: true
