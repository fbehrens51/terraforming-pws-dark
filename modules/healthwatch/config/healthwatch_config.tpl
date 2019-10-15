product-name: p-healthwatch
product-properties:
  .healthwatch-forwarder.boshhealth_instance_count:
    value: 1
  .healthwatch-forwarder.boshtasks_instance_count:
    value: 2
  .healthwatch-forwarder.canary_instance_count:
    value: 2
  .healthwatch-forwarder.cli_instance_count:
    value: 2
  .healthwatch-forwarder.foundation_name:
    value: ${env_name}
  .healthwatch-forwarder.health_check_az:
    value: ${health_check_availability_zone}
  .healthwatch-forwarder.ingestor_instance_count:
    value: 4
  .healthwatch-forwarder.opsman_instance_count:
    value: 2
  .healthwatch-forwarder.publish_to_eva:
    value: true
  .healthwatch-forwarder.worker_instance_count:
    value: 4
  .mysql.skip_name_resolve:
    value: true
  .properties.boshtasks:
    selected_option: enable
    value: enable
  .properties.boshtasks.enable.bosh_taskcheck_password:
    value:
      secret: ${bosh_task_uaa_client_secret}
  .properties.boshtasks.enable.bosh_taskcheck_username:
    value: healthwatch_client
  .properties.indicators_selector:
    selected_option: inactive
    value: "No"
  .properties.opsman:
    selected_option: enable
    value: enable
  .properties.opsman.enable.url:
    value: ${om_url}
  .properties.syslog_selector:
    selected_option: active_with_tls
    value: Yes with TLS encryption
  .properties.syslog_selector.active_with_tls.syslog_address:
    value: ${splunk_syslog_host}
  .properties.syslog_selector.active_with_tls.syslog_port:
    value: ${splunk_syslog_port}
  .properties.syslog_selector.active_with_tls.syslog_permitted_peer:
    value: ${splunk_syslog_host}
  .properties.syslog_selector.active_with_tls.syslog_ca_cert:
    value: |
      ${indent(6, splunk_syslog_ca_cert)}
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
  healthwatch-forwarder:
    instances: automatic
    persistent_disk:
      size_mb: automatic
    instance_type:
      id: automatic
    internet_connected: false
  mysql:
    instances: automatic
    persistent_disk:
      size_mb: automatic
    instance_type:
      id: automatic
    internet_connected: false
  redis:
    instances: automatic
    persistent_disk:
      size_mb: automatic
    instance_type:
      id: automatic
    internet_connected: false
errand-config:
  delete-space:
    pre-delete-state: true
  push-apps:
    post-deploy-state: true
  smoke-tests:
    post-deploy-state: true
