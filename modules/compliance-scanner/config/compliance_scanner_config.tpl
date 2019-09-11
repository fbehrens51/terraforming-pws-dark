product-name: p-compliance-scanner
product-properties:
  .properties.benchmarks:
    value:
    - base
    - recommended
    - strict
    - stig
  .properties.ntp_server:
    value: ${ntp_servers}
  .properties.openfile_limit:
    value: 2048
  .properties.scan_report_formats:
    value:
    - log
    - xml
    - html
  .properties.scanner_timeout:
    value: 1200
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
    instances: automatic
    instance_type:
      id: automatic
    internet_connected: false
errand-config:
  scan_results:
    post-deploy-state: false