product-name: pws-dark-concourse-tile
syslog-properties:
  enabled: true
  address: ${splunk_syslog_host}
  port: ${splunk_syslog_port}
  transport_protocol: tcp
  tls_enabled: true
  ssl_ca_certificate: |
    ${indent(4, splunk_syslog_ca_cert)}
  permitted_peer: ${splunk_syslog_host}
product-properties:
  .properties.web_tls_cert:
    value:
      cert_pem: |
        ${indent(8, concourse_cert_pem)}
      private_key_pem: |
        ${indent(8, concourse_private_key_pem)}
  .properties.uaa_tls_cert:
    value:
      cert_pem: |
        ${indent(8, uaa_cert_pem)}
      private_key_pem: |
        ${indent(8, uaa_private_key_pem)}
  .properties.concourse_external_url:
    value: ${plane_endpoint}
  .properties.ca_certificate:
    value: |
      ${indent(6, ca_certificate)}
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
  .properties.postgres_ca_cert:
    value: |
      ${indent(6, postgres_ca_cert)}
  .properties.admin_users:
    value:
    ${indent(4, admin_users)}
network-properties:
  network:
    name: control-plane-subnet
  other_availability_zones:
    ${control_plane_vpc_azs}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  uaa:
    instances: automatic
    instance_type:
      id: automatic
    internet_connected: false
    elb_names: ${uaa_elb_names}
  web:
    instances: automatic
    instance_type:
      id: automatic
    internet_connected: false
    elb_names: ${web_elb_names}
  worker:
    instances: automatic
    instance_type:
      id: r5.4xlarge
    internet_connected: false
    additional_vm_extensions:
    - worker_instance_profile

