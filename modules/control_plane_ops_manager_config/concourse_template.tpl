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
  .properties.external_url:
    value: "https://${plane_endpoint}"
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
  .properties.postgres_ca_cert:
    value: |
      ${indent(6, postgres_ca_cert)}
  .properties.users_to_add:
    value:
    ${indent(4, users_to_add)}
network-properties:
  network:
    name: control-plane-subnet
  other_availability_zones:
    ${control_plane_vpc_azs}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  web:
    instances: automatic
    instance_type:
      id: automatic
    internet_connected: false
    elb_names: ${web_elb_names}
  worker:
    instances: automatic
    instance_type:
      id: r5.2xlarge
    internet_connected: false
    additional_vm_extensions:
    - worker_instance_profile

