product-name: credhub-service-broker
product-properties:
  .properties.allow_paid_service_plans:
    value: false
  .properties.apply_open_security_group:
    value: false
  .properties.credhub_broker_enable_global_access_to_plans:
    value: true
  .properties.org:
    value: credhub-service-broker-org
  .properties.space:
    value: credhub-service-broker-space
network-properties:
  network:
    name: ${network_name}
  other_availability_zones: ${az_yaml}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  delete-all:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.credhub_service_broker}
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
  deploy-all:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: []
    instance_type:
      id: ${scale.credhub_service_broker}
    instances: automatic
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
errand-config:
  delete-all:
    pre-delete-state: true
  deploy-all:
    post-deploy-state: true
