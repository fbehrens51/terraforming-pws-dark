az-configuration:
- name: ${pas_subnet_availability_zone}
network-assignment:
  network:
    name: pcf-management-network
  other_availability_zones: []
  singleton_availability_zone:
    name: ${singleton_availability_zone}
networks-configuration:
  icmp_checks_enabled: false
  networks:
  - name: pcf-management-network
    subnets:
    - iaas_identifier: ${pas_subnet_subnet_id}
      cidr: ${pas_subnet_cidr}
      dns: ${pas_subnet_dns}
      # Gateway is the first IP address in the CIDR range.  For example, the
      # gateway for `10.11.12.0/24` is `10.11.12.1`.
      gateway: ${pas_subnet_gateway}
      # Reserved ips are the first four IP addresses in the CIDR range.  For
      # example, the reserved range for `10.11.12.0/24` is `10.11.12.1-10.11.12.4`.
      reserved_ip_ranges: ${pas_subnet_reserved_ips}
      # Use singleton_availability_zone from the previous section
      availability_zone_names:
      - ${pas_subnet_availability_zone}

properties-configuration:
  director_configuration:
    allow_legacy_agents: true
    blobstore_type: local
    bosh_recreate_on_next_deploy: false
    bosh_recreate_persistent_disks_on_next_deploy: false
    custom_ssh_banner: |
      ${indent(6, custom_ssh_banner)}
    database_type: external
    director_worker_count: 5
    encryption:
      keys: []
      providers: []
    external_database_options:
      connection_options: {}
      database: ${rds_database}
      host: ${rds_address}
      port: ${rds_port}
      tls_ca: null
      tls_certificate: null
      tls_enabled: false
      user: ${rds_username}
      password: ${rds_password}
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
      env: ${env_name}
    keep_unreachable_vms: false
    local_blobstore_options:
      tls_enabled: true
    ntp_servers_string: ${ntp_servers}
    post_deploy_enabled: true
    resurrector_enabled: true
    retry_bosh_deploys: false
    skip_director_drain: true
  dns_configuration:
    excluded_recursors: []
    handlers: []
  iaas_configuration:
    additional_cloud_properties:
      connection_options:
        ca_cert: |
          ${indent(10, iaas_configuration_endpoints_ca_cert)}
      ec2_endpoint: ${ec2_endpoint}
      elb_endpoint: ${elb_endpoint}
    encrypted: true
    iam_instance_profile: ${iaas_configuration_iam_instance_profile}
    key_pair_name: ${iaas_configuration_ssh_key_pair_name}
    name: default
    region: ${iaas_configuration_region}
    security_group: ${iaas_configuration_security_group}
    ssh_private_key: |
      ${indent(6, iaas_configuration_ssh_private_key)}
  security_configuration:
    generate_vm_passwords: true
    opsmanager_root_ca_trusted_certs: false
    trusted_certificates: |
      ${indent(6, security_configuration_trusted_certificates)}
  syslog_configuration:
    enabled: false
resource-configuration:
  compilation:
    instances: automatic
    instance_type:
      id: automatic
    internet_connected: false
  director:
    instances: automatic
    persistent_disk:
      size_mb: automatic
    instance_type:
      id: automatic
    internet_connected: false
vmextensions-configuration:
- name: s3_instance_profile
  cloud_properties:
    iam_instance_profile: ${blobstore_instance_profile}

