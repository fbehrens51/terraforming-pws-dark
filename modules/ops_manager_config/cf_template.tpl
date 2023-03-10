product-name: cf
product-properties:
  .cloud_controller.allow_app_ssh_access:
    value: false
  .cloud_controller.apps_domain:
    value: ${apps_domain}
  .cloud_controller.default_app_memory:
    value: 1024
  .cloud_controller.default_app_ssh_access:
    value: false
  .cloud_controller.default_disk_quota_app:
    value: 1024
  .cloud_controller.default_quota_max_number_services:
    value: 100
  .cloud_controller.default_quota_memory_limit_mb:
    value: 10240
  .cloud_controller.enable_custom_buildpacks:
    value: false
  .cloud_controller.encrypt_key:
    value:
      secret: ${cloud_controller_encrypt_key_secret}
  .cloud_controller.max_disk_quota_app:
    value: 2048
  .cloud_controller.max_file_size:
    value: 1024
  .cloud_controller.max_package_size:
    value: 2147483648
  .cloud_controller.security_event_logging_enabled:
    value: true
  .cloud_controller.staging_timeout_in_seconds:
    value: 900
  .cloud_controller.system_domain:
    value: ${system_domain}
  .diego_brain.starting_container_count_maximum:
    value: 200
  .mysql.cli_history:
    value: true
  .mysql.max_connections:
    value: 3500
  .mysql.prevent_node_auto_rejoin:
    value: false
  .mysql.remote_admin_access:
    value: false
  .mysql_monitor.poll_frequency:
    value: 30
  .mysql_monitor.recipient_email:
    value: fake@email.com
  .mysql_monitor.write_read_delay:
    value: 20
  .mysql_proxy.enable_inactive_mysql_port:
    value: false
  .mysql_proxy.shutdown_delay:
    value: 30
  .mysql_proxy.startup_delay:
    value: 0
  .nfs_server.blobstore_internal_access_rules:
    value: allow 10.0.0.0/8;,allow 172.16.0.0/12;,allow 192.168.0.0/16;
  .properties.app_graceful_shutdown_period_in_seconds:
    value: 10
  .properties.app_log_rate_limiting:
    selected_option: disable
    value: disable
  .properties.autoscale_api_disable_connection_pooling:
    value: false
  .properties.autoscale_api_instance_count:
    value: 1
  .properties.autoscale_enable_notifications:
    value: false
  .properties.autoscale_enable_verbose_logging:
    value: false
  .properties.autoscale_instance_count:
    value: 3
  .properties.autoscale_metric_bucket_count:
    value: 120
  .properties.autoscale_scaling_interval_in_seconds:
    value: 35
  .properties.cc_api_rate_limit:
    selected_option: disable
    value: disable
  .properties.cc_logging_level:
    value: info
  .properties.ccdb_connection_validation_timeout:
    value: 3600
  .properties.ccdb_read_timeout:
    value: 3600
  .properties.ccng_monit_http_healthcheck_timeout_per_retry:
    value: 6
  .properties.cf_networking_database_connection_timeout:
    value: 120
  .properties.cf_networking_enable_space_developer_self_service:
    value: true
  .properties.cf_networking_internal_domains:
    value:
    - name: apps.internal
  .properties.cloud_controller_audit_events_cutoff_age_in_days:
    value: 31
  .properties.cloud_controller_completed_tasks_cutoff_age_in_days:
    value: 31
  .properties.cloud_controller_default_health_check_timeout:
    value: 60
  .properties.cloud_controller_post_bbr_healthcheck_timeout_in_seconds:
    value: 60
  .properties.cloud_controller_temporary_disable_deployments:
    value: false
  .properties.cloud_controller_worker_alert_if_above_mb:
    value: 384
  .properties.cloud_controller_worker_restart_if_above_mb:
    value: 512
  .properties.cloud_controller_worker_restart_if_consistently_above_mb:
    value: 384
  .properties.container_networking:
    selected_option: enable
    value: enable
  .properties.container_networking_interface_plugin:
    selected_option: silk
    value: silk
  .properties.container_networking_interface_plugin.silk.enable_dynamic_asgs:
    value: false
  .properties.container_networking_interface_plugin.silk.enable_log_traffic:
    value: true
  .properties.container_networking_interface_plugin.silk.enable_policy_enforcement:
    value: true
  .properties.container_networking_interface_plugin.silk.iptables_accepted_udp_logs_per_sec:
    value: 100
  .properties.container_networking_interface_plugin.silk.iptables_denied_logs_per_sec:
    value: 1
  .properties.container_networking_interface_plugin.silk.network_mtu:
    value: 1454
  .properties.container_networking_interface_plugin.silk.vtep_port:
    value: 4789
  .properties.credhub_database:
    selected_option: internal_mysql
    value: internal_mysql
  .properties.credhub_hsm_provider_client_certificate:
    value: {}
  .properties.credhub_hsm_provider_partition_password:
    value: {}
  .properties.credhub_internal_provider_keys:
    value:
    - key:
        secret: ${credhub_encryption_password}
      name: credhub
      primary: true
  .properties.default_loggregator_drain_metadata:
    value: true
  .properties.diego_database_max_open_connections:
    value: 100
  .properties.disable_logs_in_firehose:
    value: false
  .properties.enable_garden_containerd_mode:
    value: true
  .properties.enable_log_cache_syslog_ingestion:
    value: false
  .properties.enable_smb_volume_driver:
    value: false
  .properties.enable_tls_to_internal_pxc:
    value: false
  .properties.enable_v1_firehose:
    value: true
  .properties.enable_v2_firehose:
    value: true
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
  .properties.locket_database_max_open_connections:
    value: 200
  .properties.log_cache_max_per_source:
    value: 100000
  .properties.logging_timestamp_format:
    selected_option: rfc3339
    value: rfc3339
  .properties.metric_registrar_blacklisted_tags:
    value: deployment,job,index
  .properties.metric_registrar_enabled:
    value: true
  .properties.metric_registrar_scrape_interval_in_seconds:
    value: 35
  .properties.mysql_activity_logging:
    selected_option: enable
    value: enable
  .properties.mysql_activity_logging.enable.audit_logging_events:
    value: connect,query
  .properties.networking_poe_ssl_certs:
    value:
    - certificate:
        cert_pem: |
          ${indent(10, chomp(router_cert_pem))}
        private_key_pem: |
          ${indent(10, chomp(router_private_key_pem))}
      name: router
%{~ for index, vanity_cert in vanity_certs }
    - certificate:
        cert_pem: |
          ${indent(10, chomp(vanity_cert.cert))}
        private_key_pem: |
          ${indent(10, chomp(vanity_cert.key))}
      name: ${format("vanity-%02d", index+1)}
%{~ endfor }
  .properties.networkpolicyserver_database_max_open_connections:
    value: 200
  .properties.networkpolicyserverinternal_database_max_open_connections:
    value: 200
  .properties.nfs_volume_driver:
    selected_option: disable
    value: disable
  .properties.policy_server_asg_syncer_interval:
    value: 60
  .properties.push_apps_manager_app_poll_interval:
    value: 10
  .properties.push_apps_manager_buildpack:
    value: staticfile_buildpack
  .properties.push_apps_manager_cf_cli_packages:
    selected_option: cf_cli_v8
    value: cf_cli_v8
  .properties.push_apps_manager_currency_lookup:
    value: '{ "usd": "$", "eur": "???" }'
  .properties.push_apps_manager_display_plan_prices:
    value: false
  .properties.push_apps_manager_enable_invitations:
    value: false
  .properties.push_apps_manager_global_wrapper_bg_color:
    value: '#FFFF00'
  .properties.push_apps_manager_global_wrapper_footer_content:
    ${apps_manager_global_wrapper_footer_content}
  .properties.push_apps_manager_global_wrapper_header_content:
    ${apps_manager_global_wrapper_header_content}
  .properties.push_apps_manager_global_wrapper_text_color:
    value: '#000000'
  .properties.push_apps_manager_invitations_buildpack:
    value: nodejs_buildpack
  .properties.push_apps_manager_nav_links:
    value:
    - href: ${apps_manager_offline_docs_url}
      name: Public Documentation
    - href: ${apps_manager_docs_url}
      name: Internal Documentation
    - href: ${apps_manager_tools_url}
      name: Tools
    - href: ${apps_manager_about_url}
      name: About
    - href: ${apps_manager_docs_url}/support/
      name: Support
  .properties.push_apps_manager_offline_tools:
    value:
    - enable_offline_tools
  .properties.push_apps_manager_poll_interval:
    value: 30
  .properties.push_apps_manager_search_server_buildpack:
    value: nodejs_buildpack
  .properties.push_usage_service_cutoff_age_in_days:
    value: 365
  .properties.route_integrity:
    selected_option: mutual_tls_verify
    value: mutual_tls_verify
  .properties.route_services:
    selected_option: enable
    value: enable
  .properties.route_services.enable.ignore_ssl_cert_verification:
    value: false
  .properties.route_services.enable.internal_lookup:
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
  .properties.routing_tls_termination:
%{ if use_external_haproxy_endpoint ~}
    selected_option: load_balancer
    value: load_balancer
%{ else ~}
    selected_option: router
    value: router
%{ endif ~}
  .properties.routing_tls_version_range:
    selected_option: tls_v1_2_v1_3
    value: tls_v1_2_v1_3
  .properties.saml_signature_algorithm:
    value: SHA256
  .properties.secure_service_instance_credentials:
    value: true
  .properties.security_acknowledgement:
    value: X
  .properties.service_discovery_controller_staleness_threshold:
    value: 600
  .properties.silk_database_max_open_connections:
    value: 200
  .properties.smoke_tests:
    selected_option: on_demand
    value: on_demand
%{ if smtp_enabled == "true" ~}
  .properties.smtp_address:
    value: ${smtp_host}
  .properties.smtp_auth_mechanism:
    value: plain
  .properties.smtp_credentials:
    value:
      identity: ${smtp_user}
      password: ${smtp_password}
  .properties.smtp_enable_starttls_auto:
    value: ${smtp_tls}
  .properties.smtp_from:
    value: ${smtp_from}
  .properties.smtp_port:
    value: ${smtp_port}
%{ else ~}
  .properties.smtp_address:
    value: ''
  .properties.smtp_auth_mechanism:
    value: plain
  .properties.smtp_credentials:
    value:
      identity: ''
      password: ''
  .properties.smtp_enable_starttls_auto:
    value: false
  .properties.smtp_from:
    value: ''
  .properties.smtp_port:
    value: ''
%{ endif ~}
  .properties.syslog_agent_aggregate_drains:
    value: syslog-tls://${syslog_host}:${apps_syslog_port}
  .properties.syslog_drop_debug:
    value: true
  .properties.syslog_host:
    value: ${syslog_host}
  .properties.syslog_port:
    value: ${syslog_port}
  .properties.syslog_protocol:
    value: tcp
  .properties.syslog_tls:
    selected_option: enabled
    value: enabled
  .properties.syslog_tls.enabled.tls_ca_cert:
    value: |
      ${indent(6, syslog_ca_cert)}
  .properties.syslog_tls.enabled.tls_permitted_peer:
    value: ${syslog_host}
  .properties.syslog_use_tcp_for_file_forwarding_local_transport:
    value: false
  .properties.system_blobstore:
    selected_option: external
    value: external
  .properties.system_blobstore.external.backup_region:
    value: ${region}
  .properties.system_blobstore.external.buildpacks_bucket:
    value: ${pas_buildpacks_bucket}
  .properties.system_blobstore.external.droplets_bucket:
    value: ${pas_droplets_bucket}
  .properties.system_blobstore.external.encryption:
    value: true
  .properties.system_blobstore.external.encryption_kms_key_id:
    value: ${kms_key_id}
  .properties.system_blobstore.external.endpoint:
    value: ${s3_endpoint}
  .properties.system_blobstore.external.iam_instance_profile_authentication:
    value: true
  .properties.system_blobstore.external.packages_bucket:
    value: ${pas_packages_bucket}
  .properties.system_blobstore.external.path_style_s3_urls:
    value: true
  .properties.system_blobstore.external.region:
    value: ${region}
  .properties.system_blobstore.external.resources_bucket:
    value: ${pas_resources_bucket}
  .properties.system_blobstore.external.buildpacks_backup_bucket:
    value: ${pas_buildpacks_backup_bucket}
  .properties.system_blobstore.external.droplets_backup_bucket:
    value: ${pas_droplets_backup_bucket}
  .properties.system_blobstore.external.packages_backup_bucket:
    value: ${pas_packages_backup_bucket}
  .properties.system_blobstore.external.secret_key:
    value: {}
  .properties.system_blobstore.external.signature_version:
    value: "4"
  .properties.system_blobstore.external.versioning:
    value: true
  .properties.system_blobstore_backup_level:
    selected_option: all
    value: all
  .properties.system_blobstore_ccdroplet_max_staged_droplets_stored:
    value: 2
  .properties.system_blobstore_ccpackage_max_valid_packages_stored:
    value: 2
  .properties.system_database:
    selected_option: external
    value: external
  .properties.system_database.external.account_password:
    value:
      secret: ${rds_password}
  .properties.system_database.external.account_username:
    value: ${rds_username}
  .properties.system_database.external.app_usage_service_password:
    value:
      secret: ${rds_password}
  .properties.system_database.external.app_usage_service_username:
    value: ${rds_username}
  .properties.system_database.external.autoscale_password:
    value:
      secret: ${rds_password}
  .properties.system_database.external.autoscale_username:
    value: ${rds_username}
  .properties.system_database.external.ca_cert:
    value: |
      ${indent(6, rds_ca_cert)}
  .properties.system_database.external.ccdb_password:
    value:
      secret: ${rds_password}
  .properties.system_database.external.ccdb_username:
    value: ${rds_username}
  .properties.system_database.external.credhub_password:
    value:
      secret: ${rds_password}
  .properties.system_database.external.credhub_username:
    value: ${rds_username}
  .properties.system_database.external.diego_password:
    value:
      secret: ${rds_password}
  .properties.system_database.external.diego_username:
    value: ${rds_username}
  .properties.system_database.external.host:
    value: ${rds_address}
  .properties.system_database.external.locket_password:
    value:
      secret: ${rds_password}
  .properties.system_database.external.locket_username:
    value: ${rds_username}
  .properties.system_database.external.networkpolicyserver_password:
    value:
      secret: ${rds_password}
  .properties.system_database.external.networkpolicyserver_username:
    value: ${rds_username}
  .properties.system_database.external.notifications_password:
    value:
      secret: ${rds_password}
  .properties.system_database.external.notifications_username:
    value: ${rds_username}
  .properties.system_database.external.port:
    value: ${rds_port}
  .properties.system_database.external.routing_password:
    value:
      secret: ${rds_password}
  .properties.system_database.external.routing_username:
    value: ${rds_username}
  .properties.system_database.external.silk_password:
    value:
      secret: ${rds_password}
  .properties.system_database.external.silk_username:
    value: ${rds_username}
  .properties.system_database.external.uaa_password:
    value:
      secret: ${rds_password}
  .properties.system_database.external.uaa_username:
    value: ${rds_username}
  .properties.system_database.external.validate_hostname:
    value: true
  .properties.system_metrics_scraper_scrape_interval:
    value: 1m
  .properties.tcp_routing:
    selected_option: disable
    value: disable
  .properties.uaa:
    selected_option: internal
    value: internal
  .properties.uaa.internal.password_expires_after_months:
    value: ${password_policies_expires_after_months}
  .properties.uaa.internal.password_max_retry:
    value: ${password_policies_max_retry}
  .properties.uaa.internal.password_min_length:
    value: ${password_policies_min_length}
  .properties.uaa.internal.password_min_lowercase:
    value: ${password_policies_min_lowercase}
  .properties.uaa.internal.password_min_numeric:
    value: ${password_policies_min_numeric}
  .properties.uaa.internal.password_min_special:
    value: ${password_policies_min_special}
  .properties.uaa.internal.password_min_uppercase:
    value: ${password_policies_min_uppercase}
  .properties.uaa_database:
    selected_option: internal_mysql
    value: internal_mysql
  .properties.uaa_session_cookie_max_age:
    value: 28800
  .properties.uaa_session_idle_timeout:
    value: 1800
  .properties.vxlan_policy_agent_asg_update_interval:
    value: 60
  .router.disable_insecure_cookies:
    value: false
  .router.drain_timeout:
    value: 900
  .router.drain_wait:
    value: 20
  .router.enable_http2:
    value: true
  .router.enable_isolated_routing:
    value: false
  .router.enable_write_access_logs:
    value: true
  .router.enable_zipkin:
    value: true
  .router.frontend_idle_timeout:
    value: ${gorouter_frontend_idle_timeout}
  .router.lb_healthy_threshold:
    value: 20
  .router.request_timeout_in_seconds:
    value: ${gorouter_request_timeout_in_seconds}
%{ if use_external_haproxy_endpoint ~}
  .router.static_ips:
    value: ${haproxy_backend_servers}
%{ endif ~}
  .uaa.apps_manager_access_token_lifetime:
    value: 3600
  .uaa.cf_cli_access_token_lifetime:
    value: 3600
  .uaa.cf_cli_refresh_token_lifetime:
    value: 3600
  .uaa.customize_password_label:
    value: Password
  .uaa.customize_username_label:
    value: Email
  .uaa.enable_uri_encoding_compatibility_mode:
    value: true
  .uaa.enforce_system_zone_policy_in_all_zones:
    value: true
  .uaa.proxy_ips_regex:
    value: 10\.\d{1,3}\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3}|169\.254\.\d{1,3}\.\d{1,3}|127\.\d{1,3}\.\d{1,3}\.\d{1,3}|172\.1[6-9]{1}\.\d{1,3}\.\d{1,3}|172\.2[0-9]{1}\.\d{1,3}\.\d{1,3}|172\.3[0-1]{1}\.\d{1,3}\.\d{1,3}
  .uaa.service_provider_key_credentials:
    value:
      cert_pem: |
        ${indent(8, uaa_service_provider_key_credentials_cert_pem)}
      private_key_pem: |
        ${indent(8, uaa_service_provider_key_credentials_private_key_pem)}
  .uaa.service_provider_key_password:
    value: {}
network-properties:
  network:
    name: pas
  other_availability_zones:
    ${pas_vpc_azs}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  backup_restore:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions:
    - s3_instance_profile
    elb_names: []
    instance_type:
      id: ${scale.backup_restore}
    instances: automatic
    internet_connected: false
    persistent_disk:
      size_mb: automatic
    swap_as_percent_of_memory_size: automatic
  clock_global:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.clock_global}
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
  cloud_controller:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions:
    - s3_instance_profile
    elb_names: []
    instance_type:
      id: ${scale.cloud_controller}
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
  cloud_controller_worker:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions:
    - s3_instance_profile
    elb_names: []
    instance_type:
      id: ${scale.cloud_controller_worker}
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
  credhub:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.credhub}
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
  diego_brain:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.diego_brain}
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
  diego_cell:
    max_in_flight: 4%
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.diego_cell}
    # 4 r5.large instances is our standard 'Isolation segment' capacity @ 16
    # GB per instance, this value should also be updated in the isolation segment config
    instances: 4
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
  diego_database:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.diego_database}
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
  doppler:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.doppler}
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
  ha_proxy:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: automatic
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
  log_cache:
    max_in_flight: 20%
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.log_cache}
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
  loggregator_trafficcontroller:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.loggregator_trafficcontroller}
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
  mysql:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: automatic
    instances: 0
    internet_connected: false
    persistent_disk:
      size_mb: automatic
    swap_as_percent_of_memory_size: automatic
  mysql_monitor:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: automatic
    instances: 0
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
  mysql_proxy:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: automatic
    instances: 0
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
  nats:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.nats}
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
  nfs_server:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: automatic
    instances: 0
    internet_connected: false
    persistent_disk:
      size_mb: automatic
    swap_as_percent_of_memory_size: automatic
  router:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: ${router_elb_names}
    instance_type:
      id: ${scale.router}
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
  tcp_router:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: automatic
    instances: 0
    internet_connected: false
    persistent_disk:
      size_mb: automatic
    swap_as_percent_of_memory_size: automatic
  uaa:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.uaa}
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
errand-config:
  deploy-autoscaler:
    post-deploy-state: ${errands_deploy_autoscaler}
  deploy-notifications:
    post-deploy-state: ${errands_deploy_notifications}
  deploy-notifications-ui:
    post-deploy-state: ${errands_deploy_notifications_ui}
  metric_registrar_smoke_test:
    post-deploy-state: ${errands_metric_registrar_smoke_test}
  nfsbrokerpush:
    post-deploy-state: ${errands_nfsbrokerpush}
  push-apps-manager:
    post-deploy-state: true
  push-offline-docs:
    post-deploy-state: true
  push-usage-service:
    post-deploy-state: ${errands_push_usage_service}
  rotate_cc_database_key:
    post-deploy-state: ${errands_rotate_cc_database_key}
  smbbrokerpush:
    post-deploy-state: ${errands_smbbrokerpush}
  smoke_tests:
    post-deploy-state: ${errands_smoke_tests}
  test-autoscaling:
    post-deploy-state: ${errands_test_autoscaling}

