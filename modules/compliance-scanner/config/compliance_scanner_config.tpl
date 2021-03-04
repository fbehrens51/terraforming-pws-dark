product-name: p-compliance-scanner
product-properties:
  .properties.benchmarks:
    value:
    - Base
    - CIS-Level-2
    - STIG
  .properties.bucket_selector:
    selected_option: aws
    value: aws
  .properties.bucket_selector.aws.bucket_name:
    value: ${reports_bucket_name}
  .properties.bucket_selector.aws.bucket_region:
    value: ${reports_bucket_region}
  .properties.cpu_limit:
    value: 50
  .properties.detection_timeout:
    value: 3
  .properties.enforce_cpu_limit:
    selected_option: disabled
    value: disabled
  .properties.login_banner:
    value: |
      ${indent(6, custom_ssh_banner)}
  .properties.ntp_server:
    value: ${ntp_servers}
  .properties.scan_report_formats:
    value:
    - csv
    - html
  .properties.scanner_timeout:
    value: 2400
  .properties.scheduled_scan_enabled:
    selected_option: disabled
    value: disabled
  .properties.syslog_host:
    value: ${syslog_host}
  .properties.syslog_port:
    value: ${syslog_port}
network-properties:
  network:
    name: ${network_name}
  other_availability_zones:
  - name: ${availability_zones}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  oscap_store:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions:
    - s3_instance_profile
    elb_names: []
    instance_type:
      id: ${scale.oscap_store}
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
errand-config:
  scan_results:
    post-deploy-state: false
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
