product-name: p-compliance-scanner
product-properties:
  .properties.benchmarks:
    value:
    - Base
    - CIS-Level-1
    - CIS-Level-2
    - STIG
  .properties.bucket_selector:
    selected_option: none
    value: none
  .properties.enforce_cpu_limit:
    selected_option: disabled
    value: disabled
  .properties.login_banner:
    value: ${custom_ssh_banner}
  .properties.ntp_server:
    value: ${ntp_servers}
  .properties.scan_report_formats:
    value:
    - csv
    - xml
    - html
  .properties.scanner_timeout:
    value: 1200
  .properties.scheduled_scan_enabled:
    selected_option: disabled
    value: disabled
  .properties.syslog_host:
    value: ${splunk_syslog_host}
  .properties.syslog_port:
    value: ${splunk_syslog_port}
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
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: automatic
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
errand-config:
  scan_results:
    post-deploy-state: false
syslog-properties:
  address: ${splunk_syslog_host}
  custom_rsyslog_configuration: null
  enabled: true
  forward_debug_logs: false
  permitted_peer: ${splunk_syslog_host}
  port: ${splunk_syslog_port}
  queue_size: null
  ssl_ca_certificate: |
    ${indent(4, splunk_syslog_ca_cert)}
  tls_enabled: true
  transport_protocol: tcp