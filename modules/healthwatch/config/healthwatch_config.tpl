product-name: p-healthwatch2
product-properties:
  .grafana.additional_cipher:
    value: ${grafana_additional_cipher_suites}
  .grafana.enable_indipro_integration:
    value: true
  .grafana.enable_login_form:
    value: true
  .grafana.enable_mysql:
    value: false
  .grafana.enable_rabbitmq:
    value: false
  .grafana.root_url:
    value: ${grafana_root_url}
  .grafana.ssl_ca_certificate:
    value: |-
      ${indent(6, chomp(root_ca_cert))}
  .grafana.ssl_certificates:
    value:
      cert_pem: |
        ${indent(8, chomp(grafana_server_cert))}
      private_key_pem: |
        ${indent(8, chomp(grafana_server_key))}
  .properties.canary_exporter_targets:
    value:
    - address: ${canary_url}
  .properties.dashboard_discovery:
    selected_option: dynamic
    value: dynamic
  .properties.enable_telemetry:
    value: false
  .properties.grafana_authentication:
    selected_option: uaa
    value: uaa
  .properties.grafana_authentication.uaa.client_id:
    value: grafana
  .properties.grafana_authentication.uaa.client_secret:
    value:
      secret: ${grafana_uaa_client_secret}
  .properties.grafana_authentication.uaa.root_url:
    value: ${uaa_url}
  .properties.grafana_authentication.uaa.tls_skip_verify_insecure:
    value: false
  .properties.grafana_proxy:
    selected_option: disabled
    value: disabled
  .properties.opsman_url:
    value: ${ops_canary_url}
  .properties.pks_cluster_discovery:
    selected_option: disabled
    value: disabled
  .properties.scrape_configs:
    value:
    # We use the grafana_server_cert/key for the node_exporters on each VM
    - ca: |
        ${indent(8, chomp(root_ca_cert))}
      # We are only enabling TLS for the encryption. Each host has a different name,
      # and the cert will not match them. The list is also dynamic, so we can't
      # pre-allocate a cert with all the names.
      insecure_skip_verify: true
      scrape_job: |
        job_name: 'ec2'
        scheme: https
        ec2_sd_configs:
        - region: ${region}
          port: 9100
        relabel_configs:
        # Only monitor instances with a MetricsKey tag matchine mine
        - source_labels: [__meta_ec2_tag_MetricsKey]
          regex: ${metrics_key}
          action: keep
        - source_labels: [__meta_ec2_tag_Name]
          target_label: name_tag
        - source_labels: [__meta_ec2_availability_zone]
          target_label: availability_zone
        - source_labels: [__meta_ec2_instance_id]
          target_label: instance_id
      server_name: null
    - ca: |
        ${indent(8, chomp(root_ca_cert))}
      insecure_skip_verify: false
      scrape_job: |-
        job_name: 'fluentd'
        metrics_path: /aggregated_metrics
        static_configs:
        - targets:
          - ${fluentd_root_url}
      server_name: null
  .properties.smtp:
%{ if smtp_enabled != "true" ~}
    selected_option: disabled
    value: disabled
%{ else ~}
    selected_option: enabled
    value: enabled
  .properties.smtp.enabled.from_address:
    value: ${smtp_from}
  .properties.smtp.enabled.host:
    value: ${smtp_host}
  .properties.smtp.enabled.password:
    value:
      secret: ${smtp_password}
  .properties.smtp.enabled.port:
    value: ${smtp_port}
  .properties.smtp.enabled.skip_verify:
    value: false
  .properties.smtp.enabled.tls_credentials:
    value:
      cert_pem: |
        ${indent(8, chomp(grafana_server_cert))}
      private_key_pem: |
        ${indent(8, chomp(grafana_server_key))}
  .properties.smtp.enabled.user:
    value: ${smtp_user}
%{ endif ~}
  .tsdb.canary_exporter_port:
    value: 9115
  .tsdb.disk_chunk_size:
    value: 6144
  .tsdb.memory_chunk_size:
    value: 4096
  .tsdb.scrape_interval:
    value: 15s
network-properties:
  network:
    name: ${network_name}
  other_availability_zones:
  ${hw_vpc_azs}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  grafana:
    max_in_flight: 5
    additional_networks: []
    additional_vm_extensions:
    - tsdb_instance_profile
    elb_names:
    - ${grafana_elb_id}
    instance_type:
      id: automatic
    instances: automatic
    internet_connected: false
    persistent_disk:
      size_mb: automatic
    swap_as_percent_of_memory_size: automatic
  pxc:
    max_in_flight: 5
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
  pxc-proxy:
    max_in_flight: 5
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
  tsdb:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions:
    - tsdb_instance_profile
    elb_names: []
    instance_type:
      id: automatic
    instances: automatic
    internet_connected: false
    persistent_disk:
      size_mb: automatic
    swap_as_percent_of_memory_size: automatic
errand-config:
  smoke-test:
    post-deploy-state: true
  update-admin-password:
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
