product-name: pws-dark-haproxy-tile
product-properties:
  .properties.allow_paid_service_plans:
    value: false
  .properties.apply_open_security_group:
    value: false
  .properties.backend_servers_list:
    value: ${haproxy_backend_servers}
  .properties.disable_http:
%{ if disable_http ~}
    value: true
%{ else ~}
    value: false
%{ endif ~}
  .properties.haproxy_backend_ca_certificate:
    value: |
      ${indent(6, router_trusted_ca_certificates)}
  .properties.haproxy_ca_certificate:
    value: |
      ${indent(6, router_trusted_ca_certificates)}
  .properties.http_to_https_redirect:
%{ if http_to_https_redirect ~}
    value: true
%{ else ~}
    value: false
%{ endif ~}
  .properties.networking_poe_ssl_certs:
    value:
    - certificate:
        cert_pem: |
          ${indent(10, chomp(router_cert_pem))}
        private_key_pem: |
          ${indent(10, chomp(router_private_key_pem))}
      name: router
%{ if vanity_cert_enabled == "true" ~}
    - certificate:
        cert_pem: |
          ${indent(10, chomp(vanity_cert_pem))}
        private_key_pem: |
          ${indent(10, chomp(vanity_private_key_pem))}
      name: vanity
%{ endif ~}
  .properties.org:
    value: pws-dark-haproxy-tile-org
  .properties.space:
    value: pws-dark-haproxy-tile-space
network-properties:
  network:
    name: pas
  other_availability_zones:
    ${pas_vpc_azs}
  singleton_availability_zone:
    name: ${singleton_availability_zone}
resource-config:
  haproxy:
    max_in_flight: 1
    additional_networks: []
    additional_vm_extensions: []
    elb_names: ${haproxy_elb_names}
    instance_type:
      id: ${scale.router}
    instances: 3
    internet_connected: false
    swap_as_percent_of_memory_size: automatic
syslog-properties:
  address: ${syslog_host}
  custom_rsyslog_configuration: null
  enabled: true
  forward_debug_logs: false
  permitted_peer: ${syslog_host}
  port: ${syslog_port}
  queue_size: null
  ssl_ca_certificate: |
    ${indent(4, syslog_ca_cert)}
  tls_enabled: true
  transport_protocol: tcp