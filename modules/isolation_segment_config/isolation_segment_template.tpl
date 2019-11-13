product-name: p-isolation-segment-${iso_seg_tile_suffix}
product-properties:
  .isolated_diego_cell_${iso_seg_tile_suffix_underscore}.placement_tag:
    value: ${iso_seg_tile_suffix}
  .isolated_router_${iso_seg_tile_suffix_underscore}.disable_insecure_cookies:
    value: false
  .isolated_router_${iso_seg_tile_suffix_underscore}.drain_wait:
    value: 20
  .isolated_router_${iso_seg_tile_suffix_underscore}.enable_write_access_logs:
    value: true
  .isolated_router_${iso_seg_tile_suffix_underscore}.enable_zipkin:
    value: true
  .isolated_router_${iso_seg_tile_suffix_underscore}.lb_healthy_threshold:
    value: 20
  .isolated_router_${iso_seg_tile_suffix_underscore}.request_timeout_in_seconds:
    value: 900
  .properties.container_networking:
    selected_option: enable
    value: enable
  .properties.enable_garden_containerd_mode:
    value: true
  .properties.enable_silk_policy_enforcement:
    value: true
  .properties.enable_smb_volume_driver:
    value: false
  .properties.garden_disk_cleanup:
    selected_option: reserved
    value: reserved
  .properties.garden_disk_cleanup.reserved.reserved_space_for_other_jobs_in_mb:
    value: 15360
  .properties.gorouter_ssl_ciphers:
    value: ECDHE-RSA-AES128-GCM-SHA256:TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
  .properties.haproxy_client_cert_validation:
    selected_option: none
    value: none
  .properties.haproxy_forward_tls:
    selected_option: disable
    value: disable
  .properties.haproxy_hsts_support:
    selected_option: disable
    value: disable
  .properties.haproxy_max_buffer_size:
    value: 16384
  .properties.haproxy_ssl_ciphers:
    value: DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384
  .properties.networking_poe_ssl_certs:
    value:
    - certificate:
        cert_pem: |
          ${indent(10, router_cert_pem)}
        private_key_pem: |
          ${indent(10, router_private_key_pem)}
      name: cert
  .properties.nfs_volume_driver:
    selected_option: disable
    value: disable
  .properties.route_integrity:
    selected_option: mutual_tls_verify
    value: mutual_tls_verify
  .properties.route_services_internal_lookup:
    value: false
  .properties.router_backend_max_conn:
    value: 500
  .properties.router_balancing_algorithm:
    selected_option: round_robin
    value: round-robin
  .properties.router_client_cert_validation:
    selected_option: request
    value: request
  .properties.router_enable_proxy:
    value: false
  .properties.router_keepalive_connections:
    selected_option: enable
    value: enable
  .properties.router_prune_all_stale_routes:
    value: false
  .properties.routing_custom_ca_certificates:
    value: |
      ${indent(6, router_trusted_ca_certificates)}
  .properties.routing_disable_http:
    value: true
  .properties.routing_log_client_ips:
    selected_option: log_client_ips
    value: log_client_ips
  .properties.routing_minimum_tls_version:
    selected_option: tls_v1_2
    value: tls_v1_2
  .properties.routing_tls_termination:
    selected_option: router
    value: router
  .properties.routing_table_sharding_mode:
    selected_option: isolation_segment_only
    value: isolation_segment_only
  .properties.skip_cert_verify:
    value: false
  .properties.system_logging:
    selected_option: enabled
    value: enabled
  .properties.system_logging.enabled.host:
    value: ${splunk_syslog_host}
  .properties.system_logging.enabled.port:
    value: ${splunk_syslog_port}
  .properties.system_logging.enabled.protocol:
    value: tcp
  .properties.system_logging.enabled.syslog_drop_debug:
    value: true
  .properties.system_logging.enabled.tls_ca_cert:
    value: |
      ${indent(6, splunk_syslog_ca_cert)}
  .properties.system_logging.enabled.tls_enabled:
    value: true
  .properties.system_logging.enabled.tls_permitted_peer:
    value: ${splunk_syslog_host}
  .properties.system_logging.enabled.use_tcp_for_file_forwarding_local_transport:
    value: false
  .properties.system_metrics_enabled:
    value: true
network-properties:
  network:
    name: pas
  other_availability_zones:
    ${pas_vpc_azs}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  isolated_diego_cell_${iso_seg_tile_suffix_underscore}:
    max_in_flight: 4%
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: automatic
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
  isolated_ha_proxy_${iso_seg_tile_suffix_underscore}:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: automatic
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
  isolated_router_${iso_seg_tile_suffix_underscore}:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: automatic
    instances: 0
    internet_connected: false
    swap_as_percent_of_memory_size: automatic

