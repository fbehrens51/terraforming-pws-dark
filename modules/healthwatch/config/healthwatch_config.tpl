product-name: p-healthwatch2
product-properties:
  .grafana.enable_indipro_integration:
    value: true
  .grafana.enable_login_form:
    value: true
  .grafana.pas_version:
    value: "2.8"
  .grafana.pks_version:
    value: disabled
  .grafana.root_url:
    value: ${grafana_root_url}
  .grafana.ssl_ca_certificate:
    value: |-
      ${indent(6, root_ca_cert)}
  .grafana.ssl_certificates:
    value:
      cert_pem: |
        ${indent(8, grafana_server_cert)}
      private_key_pem: |
        ${indent(8, grafana_server_key)}
  .properties.scrape_configs:
    value:
    - ca: null
      insecure_skip_verify: false
      scrape_job: |
        job_name: 'ec2'
        ec2_sd_configs:
        - region: ${region}
          port: 9100
        relabel_configs:
        # Only monitor instances with a ScrapeMetrics tag = true
        - source_labels: [__meta_ec2_tag_ScrapeMetrics]
          regex: true
          action: keep
        - source_labels: [__meta_ec2_tag_Name,__meta_ec2_availability_zone]
          target_label: instance
      server_name: null
  .properties.canary_exporter_targets:
    value:
    - address: ${canary_url}
  .properties.grafana_authentication:
    selected_option: basic
    value: basic
  .properties.pks_cluster_discovery:
    selected_option: disabled
    value: disabled
  .properties.remote_write_basic_auth:
    selected_option: disabled
    value: disabled
  .properties.smtp:
    selected_option: disabled
    value: disabled
  .tsdb.canary_exporter_port:
    value: 9115
  .tsdb.disk_chunk_size:
    value: 6144
  .tsdb.memory_chunk_size:
    value: 4096
  .tsdb.remote_write_batch_send_deadline:
    value: 5
  .tsdb.remote_write_certificates:
    value: {}
  .tsdb.remote_write_max_backoff:
    value: 100
  .tsdb.remote_write_max_samples_per_send:
    value: 100
  .tsdb.remote_write_max_shards:
    value: 1000
  .tsdb.remote_write_min_backoff:
    value: 30
  .tsdb.remote_write_min_shards:
    value: 1
  .tsdb.remote_write_queue_capacity:
    value: 500
  .tsdb.remote_write_skip_tls_verify:
    value: false
  .tsdb.remote_write_timeout:
    value: 30
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
    additional_vm_extensions: []
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
    additional_vm_extensions: [tsdb_instance_profile]
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

