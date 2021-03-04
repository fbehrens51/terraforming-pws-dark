product-name: pws-dark-concourse-tile
syslog-properties:
  enabled: true
  address: ${syslog_host}
  port: ${syslog_port}
  transport_protocol: tcp
  tls_enabled: true
  ssl_ca_certificate: |
    ${indent(4, chomp(syslog_ca_cert))}
  permitted_peer: ${syslog_host}
product-properties:
  .properties.web_tls_cert:
    value:
      cert_pem: |
        ${indent(8, chomp(concourse_cert_pem))}
      private_key_pem: |
        ${indent(8, chomp(concourse_private_key_pem))}
  .properties.credhub_tls_cert:
    value:
      cert_pem: |
        ${indent(8, chomp(credhub_cert_pem))}
      private_key_pem: |
        ${indent(8, chomp(credhub_private_key_pem))}
  .properties.uaa_tls_cert:
    value:
      cert_pem: |
        ${indent(8, chomp(uaa_cert_pem))}
      private_key_pem: |
        ${indent(8, chomp(uaa_private_key_pem))}
  .properties.concourse_external_url:
    value: ${plane_endpoint}
  .properties.ca_certificate:
    value: |
      ${indent(6, chomp(ca_certificate))}
  .properties.uaa_external_url:
    value: ${uaa_endpoint}
  .properties.postgres_host:
    value: ${postgres_host}
  .properties.postgres_port:
    value: ${postgres_port}
  .properties.postgres_db_name:
    value: ${postgres_db_name}
  .properties.postgres_username:
    value: ${postgres_username}
  .properties.postgres_password:
    value:
      secret: ${postgres_password}
  .properties.postgres_uaa_db_name:
    value: ${postgres_uaa_db_name}
  .properties.postgres_uaa_username:
    value: ${postgres_uaa_username}
  .properties.postgres_uaa_password:
    value:
      secret: ${postgres_uaa_password}
  .properties.postgres_credhub_db_name:
    value: ${postgres_credhub_db_name}
  .properties.postgres_credhub_username:
    value: ${postgres_credhub_username}
  .properties.postgres_credhub_password:
    value:
      secret: ${postgres_credhub_password}
  .properties.postgres_ca_cert:
    value: |
      ${indent(6, chomp(postgres_ca_cert))}
  .properties.admin_users:
    value:
    ${indent(4, chomp(admin_users))}
  .properties.credhub_endpoint:
    value: ${credhub_endpoint}
network-properties:
  network:
    name: control-plane-subnet
  other_availability_zones:
    ${chomp(control_plane_vpc_azs)}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  credhub:
    instances: automatic
    instance_type:
      id: ${scale.credhub}
    internet_connected: false
    elb_names: ${credhub_elb_names}
  uaa:
    instances: automatic
    instance_type:
      id: ${scale.uaa}
    internet_connected: false
    elb_names: ${uaa_elb_names}
  web:
    instances: automatic
    instance_type:
      id: ${scale.web}
    internet_connected: false
    elb_names: ${web_tg_names}
    additional_vm_extensions:
    - concourse-lb-security-group
  worker:
    instances: automatic
    instance_type:
      id: ${scale.worker}
    internet_connected: false
    additional_vm_extensions:
    - worker_instance_profile

