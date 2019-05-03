singleton_availability_zone: ${pas_subnet_availability_zone}

availability_zones:
- name: ${pas_subnet_availability_zone}

pcf-management-subnets:
- iaas_identifier: ${pas_subnet_subnet_id}
  cidr: ${pas_subnet_cidr}
  dns: *dns
  # Gateway is the first IP address in the CIDR range.  For example, the
  # gateway for `10.11.12.0/24` is `10.11.12.1`.
  gateway: ${pas_subnet_gateway}
  # Reserved ips are the first four IP addresses in the CIDR range.  For
  # example, the reserved range for `10.11.12.0/24` is `10.11.12.1-10.11.12.4`.
  reserved_ip_ranges: ${pas_subnet_reserved_ips}
  # Use singleton_availability_zone from the previous section
  availability_zone_names:
  - ${pas_subnet_availability_zone}

external_database:
  database: director
  host: ${rds_address}
  port: "${rds_port}"
  user: ${rds_username}
  password: '${rds_password}'
  ca_cert: *rds_ca_cert

iaas_configuration:
  <<: *iaas_config
  region: ${region}
  security_group: ${vms_security_group_id}
  ssh:
    # The name of the SSH key pair to use when starting new AWS instances
    key_pair_name: ${ssh_key_name}
    # The corresponding SSH private key
    private_key: |
      ${indent(6, ssh_private_key)}

blobstore:
  # Enter bucket names from the terraform output, they should be named
  # `env`-{buildpacks,droplets,packages,resources}-bucket-(some random number)
  buildpacks-bucket: ${pas_buildpacks_bucket}
  droplets-bucket: ${pas_droplets_bucket}
  packages-bucket: ${pas_packages_bucket}
  resources-bucket: ${pas_resources_bucket}
  # Same as region entered in iaas_configuration above
  region: ${region}
  # S3 endpoint
  endpoint: ${s3_endpoint}
  instance_profile: *blobstore_instance_profile

database:
  host: ${rds_address}
  port: ${rds_port}
  account_username: ${rds_username}
  account_password: '${rds_password}'
  app_usage_service_username: ${rds_username}
  app_usage_service_password: '${rds_password}'
  autoscale_username: ${rds_username}
  autoscale_password: '${rds_password}'
  ccdb_username: ${rds_username}
  ccdb_password: '${rds_password}'
  credhub_username: ${rds_username}
  credhub_password: '${rds_password}'
  diego_username: ${rds_username}
  diego_password: '${rds_password}'
  locket_username: ${rds_username}
  locket_password: '${rds_password}'
  networkpolicyserver_username: ${rds_username}
  networkpolicyserver_password: '${rds_password}'
  nfsvolume_username: ${rds_username}
  nfsvolume_password: '${rds_password}'
  notifications_username: ${rds_username}
  notifications_password: '${rds_password}'
  routing_username: ${rds_username}
  routing_password: '${rds_password}'
  silk_username: ${rds_username}
  silk_password: '${rds_password}'
  uaa_username: ${rds_username}
  uaa_password: '${rds_password}'
  ca_cert: *rds_ca_cert

redis:
  host: ${redis_host}
  password: '${redis_password}'
  port: 6379
  ca_cert: *redis_ca_cert