product-name: pws-dark-portal-tile
product-properties:
  .properties.allow_paid_service_plans:
    value: false
  .properties.apply_open_security_group:
    value: false
  .properties.jwt_expiration:
    value: ${jwt_expiration}
  .properties.ldap_tls_ca_cert:
    value: |
      ${indent(6, ldap_tls_ca_cert)}
  .properties.ldap_tls_client_cert:
    value:
      cert_pem: |
        ${indent(8, ldap_tls_client_cert)}
      private_key_pem: |
        ${indent(8, ldap_tls_client_key)}
  .properties.smoke_test_tls_client_cert:
    value:
      cert_pem: |
        ${indent(8, smoke_test_client_cert)}
      private_key_pem: |
        ${indent(8, smoke_test_client_key)}
  .properties.ldap_basedn:
    value: ${ldap_basedn}
  .properties.ldap_dn:
    value: ${ldap_dn}
  .properties.ldap_password:
    value:
      secret: ${ldap_password}
  .properties.ldap_host:
    value: ${ldap_host}
  .properties.ldap_port:
    value: ${ldap_port}
  .properties.ldap_role_attr:
    value: ${ldap_role_attr}
  .properties.org:
    value: system
  .properties.redis_host:
    value: ${redis_host}
  .properties.redis_port:
    value: ${redis_port}
  .properties.redis_tls_ca_cert:
    value: |
      ${indent(6, redis_ca_cert)}
  .properties.redis_password:
    value:
      secret: '${redis_password}'
  .properties.space:
    value: portal
network-properties:
  network:
    name: pcf-management-network
  other_availability_zones:
  - name: us-east-1a
  singleton_availability_zone:
    name: us-east-1a
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

