az-configuration:
  ${pas_vpc_azs}
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
${infrastructure_subnets}
  - name: pas
    subnets:
    ${pas_subnets}
  %{ for isolation_segment, subnets in isolation_segment_to_subnets }
  - name: isolation-segment-${replace(lower(isolation_segment), " ", "-")}
    subnets:
    %{ for subnet in subnets }
    - iaas_identifier: ${subnet.id}
      cidr: ${subnet.cidr_block}
      dns: ${pas_vpc_dns}
      gateway: ${cidrhost(subnet.cidr_block, 1)}
      reserved_ip_ranges: ${cidrhost(subnet.cidr_block, 1)}-${cidrhost(subnet.cidr_block, 4)}
      availability_zone_names: [${subnet.availability_zone}]
    %{ endfor ~}
  %{ endfor ~}

iaas-configurations:
- additional_cloud_properties:${iaas_configuration_endpoints_ca_cert != "" ? <<EOF

    connection_options:
      ca_cert: |
        ${indent(8, iaas_configuration_endpoints_ca_cert)}
EOF
: "" }
    ec2_endpoint: ${ec2_endpoint}
    elb_endpoint: ${elb_endpoint}
  encrypted: true
  kms_key_arn: ${kms_key_arn}
  iam_instance_profile: ${iaas_configuration_iam_instance_profile}
  key_pair_name: ${iaas_configuration_ssh_key_pair_name}
  name: default
  region: ${iaas_configuration_region}
  security_group: ${iaas_configuration_security_group}
  ssh_private_key: |
    ${indent(4, iaas_configuration_ssh_private_key)}

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
      port: "${rds_port}"
      tls_ca: |
        ${indent(8, rds_ca_cert)}
      tls_certificate: null
      tls_enabled: true
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
      smtp_password: %{ if smtp_enabled == "true" }${smtp_password}%{ endif }
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
  security_configuration:
    generate_vm_passwords: true
    opsmanager_root_ca_trusted_certs: true
    trusted_certificates: |
      ${indent(6, security_configuration_trusted_certificates)}
  syslog_configuration:
    enabled: true
    address: ${syslog_host}
    port: ${syslog_port}
    transport_protocol: tcp
    tls_enabled: true
    permitted_peer: ${syslog_host}
    ssl_ca_certificate: |
      ${indent(6, splunk_syslog_ca_cert)}

resource-configuration:
  compilation:
    instances: automatic
    instance_type:
      id: automatic
    internet_connected: false
  director:
    additional_vm_extensions:
    - disable_director_encryption
    instances: automatic
    persistent_disk:
      size_mb: "153600"
    instance_type:
      id: automatic
    internet_connected: false
vmextensions-configuration:
- name: disable_director_encryption
  cloud_properties:
    ephemeral_disk:
      encrypted: false
      kms_key_arn: ~
      size: 65_536
      type: gp2
- name: s3_instance_profile
  cloud_properties:
    iam_instance_profile: ${blobstore_instance_profile}
- name: tsdb_instance_profile
  cloud_properties:
    iam_instance_profile: ${tsdb_instance_profile}
%{ for vpc_id, security_group in isolation_segment_to_security_groups }
- name: isolation-segment-${vpc_id}
  cloud_properties:
    security_groups:
    - ${security_group.name}
%{ endfor ~}