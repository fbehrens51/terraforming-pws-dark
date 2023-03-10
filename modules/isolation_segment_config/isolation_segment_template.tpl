product-name: p-isolation-segment-${iso_seg_tile_suffix}
product-properties:
  .isolated_router_${iso_seg_tile_suffix_underscore}.disable_insecure_cookies:
    value: false
  .isolated_router_${iso_seg_tile_suffix_underscore}.drain_timeout:
    value: 900
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
  .properties.app_graceful_shutdown_period_in_seconds:
    value: 10
  .properties.app_log_rate_limiting:
    selected_option: disable
    value: disable
  .properties.compute_isolation:
    selected_option: ${compute_isolation}
    value: ${compute_isolation}
%{ if compute_enabled == true ~}
  .properties.compute_isolation.enabled.isolation_segment_name:
    value: ${iso_seg_tile_suffix}
%{ endif ~}
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
          ${indent(10, chomp(router_cert_pem))}
        private_key_pem: |
          ${indent(10, chomp(router_private_key_pem))}
      name: cert
%{~ for index, vanity_cert in vanity_certs }
    - certificate:
        cert_pem: |
          ${indent(10, chomp(vanity_cert.cert))}
        private_key_pem: |
          ${indent(10, chomp(vanity_cert.key))}
      name: ${format("vanity-%02d", index+1)}
%{~ endfor }
  .properties.networking_point_of_entry:
    selected_option: terminate_at_router
    value: terminate_at_router
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
    value: true
  .properties.router_keepalive_connections:
    selected_option: enable
    value: enable
  .properties.router_only_trust_client_ca_certs:
    selected_option: enable
    value: enable
  .properties.router_only_trust_client_ca_certs.enable.client_ca_certs:
    value: |
      ${indent(6, router_trusted_ca_certificates)}
  .properties.router_sticky_session_cookie_names:
    value:
    - name: JSESSIONID
  .properties.routing_custom_ca_certificates:
    value: |
      ${indent(6, router_trusted_ca_certificates)}
  .properties.routing_disable_http:
    value: true
  .properties.routing_log_client_ips:
    selected_option: log_client_ips
    value: log_client_ips
  .properties.routing_table_sharding_mode:
    selected_option: ${routing_table_sharding_mode}
    value: ${routing_table_sharding_mode}
  .properties.routing_tls_termination:
    selected_option: router
    value: router
  .properties.routing_tls_version_range:
    selected_option: tls_v1_2_v1_3
    value: tls_v1_2_v1_3
  .properties.smoke_tests_isolation:
    selected_option: on_demand
    value: on_demand
  .properties.system_logging:
    selected_option: enabled
    value: enabled
  .properties.system_logging.enabled.host:
    value: ${syslog_host}
  .properties.system_logging.enabled.port:
    value: ${syslog_port}
  .properties.system_logging.enabled.protocol:
    value: tcp
  .properties.system_logging.enabled.syslog_drop_debug:
    value: true
  .properties.system_logging.enabled.tls_ca_cert:
    value: |
      ${indent(6, syslog_ca_cert)}
  .properties.system_logging.enabled.tls_enabled:
    value: true
  .properties.system_logging.enabled.tls_permitted_peer:
    value: ${syslog_host}
  .properties.system_logging.enabled.use_tcp_for_file_forwarding_local_transport:
    value: false
network-properties:
  network:
    name: ${network_name}
  other_availability_zones:
    ${pas_vpc_azs}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  isolated_diego_cell_${iso_seg_tile_suffix_underscore}:
    max_in_flight: 4%
    additional_networks: []
    additional_vm_extensions: %{if compute_enabled == true ~}[isolation-segment-${vpc_id}]%{else}[]%{endif}
    elb_names: []
    # 4 r5.large instances is our standard 'Isolation segment' capacity @ 16
    # GB per instance, this value should also be updated in the isolation segment config
    # the 5th instance allows for upgrades/repaves while allowing for 100% customer utilization of 4 instances.
    instances: ${instance_count}
    instance_type:
      id: ${scale.isolated_diego_cell}
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
    elb_names: %{if elb_name == "" ~}[]%{else}[${elb_name}]%{endif}
    instance_type:
      id: ${scale.router}
    instances: %{if router_enabled == true ~}3%{else}0%{endif}
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
errand-config:
  smoke_tests_isolation:
    post-deploy-state: %{if compute_enabled == true ~}true%{else}false%{endif}

