product-name: control-plane
product-properties:
  .properties.control_plane_database:
    selected_option: internal
    value: internal
  .properties.tls:
    value:
      cert_pem: |
        ${indent(8, concourse_cert_pem)}
      private_key_pem: |
        ${indent(8, concourse_private_key_pem)}
  .properties.ca_cert:
    value: |
      ${indent(6, trusted_ca_certs)}
  .properties.uaa_endpoint:
    value: "${uaa_endpoint}"
  .properties.credhub_endpoint:
    value: "${credhub_endpoint}"
  .properties.plane_endpoint:
    value: "${plane_endpoint}"
network-properties:
  network:
    name: control-plane-subnet
  other_availability_zones:
    ${control_plane_vpc_azs}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  credhub:
    instances: automatic
    instance_type:
      id: automatic
    internet_connected: false
    elb_names: ${credhub_elb_names}
  db:
    instances: automatic
    persistent_disk:
      size_mb: automatic
    instance_type:
      id: automatic
    internet_connected: false
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
      id: automatic
    internet_connected: false
    additional_vm_extensions:
    - worker_instance_profile

