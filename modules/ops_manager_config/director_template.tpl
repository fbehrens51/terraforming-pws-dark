az-configuration:
  ${indent(2, chomp(pas_vpc_azs))}
iaas-configurations:
- additional_cloud_properties:
    connection_options:
      ca_cert: |
        ${indent(8, chomp(iaas_configuration_endpoints_ca_cert))}
    ec2_endpoint: ${ec2_endpoint}
    elb_endpoint: ${elb_endpoint}
  disk_type: ${disk_type}
  encrypted: true
  iam_instance_profile: ${iaas_configuration_iam_instance_profile}
  key_pair_name: ${iaas_configuration_ssh_key_pair_name}
  kms_key_arn: ${kms_key_arn}
  name: default
  region: ${iaas_configuration_region}
  security_group: ${iaas_configuration_security_group}
  ssh_private_key: |
    ${indent(4, chomp(iaas_configuration_ssh_private_key))}
network-assignment:
  network:
    name: infrastructure
  other_availability_zones: []
  singleton_availability_zone:
    name: ${singleton_availability_zone}
networks-configuration:
  icmp_checks_enabled: false
  networks:
  - name: infrastructure
    subnets:
    ${indent(4, chomp(infrastructure_subnets))}
  - name: pas
    subnets:
    ${indent(4, chomp(pas_subnets))}
  %{~ for isolation_segment, subnets in isolation_segment_to_subnets ~}
  - name: isolation-segment-${replace(lower(isolation_segment), " ", "-")}
    subnets:
    %{~ for subnet in subnets ~}
    - availability_zone_names:
      - ${subnet.availability_zone}
      cidr: ${subnet.cidr_block}
      dns: ${pas_vpc_dns}
      gateway: ${cidrhost(subnet.cidr_block, 1)}
      iaas_identifier: ${subnet.id}
      reserved_ip_ranges: ${cidrhost(subnet.cidr_block, 1)}-${cidrhost(subnet.cidr_block, 4)}
    %{~ endfor ~}
  %{~ endfor ~}
properties-configuration:
  director_configuration:
    additional_ssh_users: %{if length(extra_users)<1}[]%{endif}
    %{~ for user in extra_users ~}
    - name: ${user.username}
      public_key: ${user.public_ssh_key}
      sudo: ${user.sudo_priv}
    %{~ endfor ~}
    blobstore_type: ${director_blobstore_location}
    bosh_director_recreate_on_next_deploy: false
    bosh_recreate_on_next_deploy: false
    bosh_recreate_persistent_disks_on_next_deploy: false
    ca_certificate_duration: 1460
    custom_ssh_banner: |
      ${indent(6, chomp(custom_ssh_banner))}
    database_type: external
    director_metrics_server_enabled: true
    director_worker_count: 5
    duration_overrides_enabled: false
    encryption:
      keys: []
      providers: []
    external_database_options:
      connection_options: {}
      database: ${rds_database}
      host: ${rds_address}
      password: ${rds_password}
      port: "${rds_port}"
      tls_ca: |
        ${indent(8, chomp(rds_ca_cert))}
      tls_certificate: null
      tls_enabled: true
      user: ${rds_username}
    hm_emailer_options:
      domain: ${smtp_domain}
      enabled: ${smtp_enabled}
      from: ${smtp_from}
      host: ${smtp_host}
      port: ${smtp_port}
      recipients:
        value: ${smtp_recipients}
      smtp_user: ${smtp_user}
      smtp_password: ${smtp_password}
      tls: ${smtp_tls}
    hm_pager_duty_options:
      enabled: false
    identification_tags:
      ${indent(6, chomp(env_name))}
    job_configuration_on_tmpfs: false
    keep_unreachable_vms: false
    leaf_certificate_duration: 730
    %{~ if director_blobstore_location == "local" ~}
    local_blobstore_options:
      tls_enabled: true
    %{~ endif ~}
    metrics_server_enabled: true
    ntp_servers_string: ${ntp_servers}
    post_deploy_enabled: true
    resurrector_enabled: true
    retry_bosh_deploys: false
    %{~ if director_blobstore_location == "s3" ~}
    s3_blobstore_options:
      backup_bucket_name:
      backup_bucket_region: ${director_blobstore_s3_endpoint}
      backup_strategy: use_versioned_bucket
      bucket_name: ${director_blobstore_bucket}
      credentials_source: env_or_profile
      enable_signed_urls: true
      endpoint: ${director_blobstore_s3_endpoint}
      region: ${iaas_configuration_region}
      signature_version: "4"
      url_style: domain-style
    %{~ endif ~}
    skip_director_drain: true
    system_metrics_runtime_enabled: true
  dns_configuration:
    excluded_recursors: []
    handlers: %{if length(forwarders)<1}[]%{endif}
    %{~ for forwarder in forwarders ~}
    - cache:
        enabled: true
      domain: ${forwarder.domain}
      source:
        recursors:
        %{~ for ip in forwarder.forwarder_ips ~}
        - ${ip}
        %{~ endfor ~}
        type: dns
    %{~ endfor ~}
  security_configuration:
    clear_default_trusted_certificates_store: true
    generate_vm_passwords: true
    opsmanager_root_ca_trusted_certs: true
    trusted_certificates: |
      ${indent(6, chomp(security_configuration_trusted_certificates))}
  syslog_configuration:
    address: ${syslog_host}
    enabled: true
    forward_debug_logs: false
    permitted_peer: ${syslog_host}
    port: ${syslog_port}
    ssl_ca_certificate: |
      ${indent(6, chomp(syslog_ca_cert))}
    tls_enabled: true
    transport_protocol: tcp
resource-configuration:
  compilation:
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.compilation}
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
  director:
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.director}
    instances: automatic
    internet_connected: false
    persistent_disk:
      size_mb: "153600"
    swap_as_percent_of_memory_size: automatic
vmextensions-configuration:
- name: s3_instance_profile
  cloud_properties:
    iam_instance_profile: ${blobstore_instance_profile}
- name: tsdb_instance_profile
  cloud_properties:
    iam_instance_profile: ${tsdb_instance_profile}
%{ for vpc_id, security_group in isolation_segment_to_security_groups ~}
- name: isolation-segment-${vpc_id}
  cloud_properties:
    security_groups:
    - ${security_group.name}
%{ endfor ~}
vmtypes-configuration: {}

