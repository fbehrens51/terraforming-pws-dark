product-name: pws-dark-runtime-config-tile
product-properties:
  .properties.force_udp_encapsulation:
    value: true
  .properties.instance_certificate_critical_period:
    value: 3
  .properties.instance_certificate_error_period:
    value: 7
  .properties.instance_certificate_info_period:
    value: 30
  .properties.instance_certificate_warn_period:
    value: 14
  .properties.ipsec_optional:
    value: true
  .properties.ipsec_subnets:
    value: ${ipsec_subnet_cidrs}
  .properties.no_ipsec_subnets:
    value: ${no_ipsec_subnet_cidrs}
  .properties.log_level:
    value: ${ipsec_log_level}
  .properties.optional_warn_interval:
    value: 1
  .properties.prestart_timeout:
    value: 30
  .properties.ssh_banner:
    value: |
      ${indent(6, ssh_banner)}
  .properties.stop_timeout:
    value: 30
