---
applications:
- name: ${portal_name}
  buildpacks:
  - go_buildpack
  routes:
  - route: ${portal_name}.${system_fqdn}
  instances: 3
  env:
    GOPACKAGENAME: pws-dark-portal
    GOVERSION: 1.13
    JWT_ALGORITHM: RS256
    JWT_EXPIRATION: 3600
    JWT_ISSUER: https://${portal_name}.${system_fqdn}/oauth/token
    JWT_KEYS_SIGN: |
      ${indent(6, chomp(jwt_key_sign))}
    JWT_KEYS_VERIFY: |
      ${indent(6, chomp(jwt_key_verify))}
    LDAP_BASEDN: ${ldap_basedn}
    LDAP_DN: ${ldap_dn}
    LDAP_HOST: ${ldap_host}
    LDAP_PASSWORD: ${ldap_password}
    LDAP_PORT: ${ldap_port}
    LDAP_ROLE_ATTR: ${ldap_role_attr}
    LDAP_TLS_CA_CERT: |
      ${indent(6, chomp(ldap_tls_ca_cert))}
    LDAP_TLS_CERT: |
      ${indent(6, chomp(ldap_tls_client_cert))}
    LDAP_TLS_KEY: |
      ${indent(6, chomp(ldap_tls_client_key))}
    MYSQL_DB_NAME: ${mysql_db_name}
    MYSQL_HOST: ${mysql_host}
    MYSQL_PASSWORD: ${mysql_password}
    MYSQL_PORT: 3306
    MYSQL_TLS_ENABLED: true
    MYSQL_USERNAME: ${mysql_username}
    MYSQL_TLS_CA_CERT: |
      ${indent(6, chomp(mysql_ca_cert))}
    LOGIN_HOST: https://login.${system_fqdn}
    UAA_URL: https://uaa.${system_fqdn}
    UAA_OIDC_NAME: ${portal_name}
    UAA_OIDC_REDIRECT_URI: https://login.${system_fqdn}/login/callback/${portal_name}
    SYSTEM_API_URL: https://api.${system_fqdn}
    SCHEME: https
    DOMAIN: ${system_fqdn}
    JWT_SIGNING_KEY: '${jsonencode({"public_key_pem"="${jwt_key_verify}","private_key_pem"="${jwt_key_sign}"})}'
    SMOKE_TEST_CLIENT_CERT: |
      ${indent(6, chomp(smoke_test_client_cert))}
    SMOKE_TEST_CLIENT_KEY: |
      ${indent(6, chomp(smoke_test_client_key))}
