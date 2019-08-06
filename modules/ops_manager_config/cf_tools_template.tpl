product-name: pws-dark-cf-tools-tile
product-properties:
  .properties.org:
    value: system
  .properties.space:
    value: cf-tools
network-properties:
  network:
    name: pas
  other_availability_zones:
    ${pas_vpc_azs}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  delete-all:
    instances: automatic
    instance_type:
      id: automatic
    internet_connected: false
  deploy-all:
    instances: automatic
    instance_type:
      id: automatic
    internet_connected: false
errand-config:
  delete-all:
    pre-delete-state: true
  deploy-all:
    post-deploy-state: true

