
locals {
  smoke_test_users = {
    smoke_test = {
      common_name = "Smoke Test User"
      ou          = "People"
      roles = [
        "TWS-C2S-DOS-MSN-ORG1-MISSION1-PROD-DEVELOPER",
        "TWS-C2S-DOS-MSN-ORG1-MISSION2-all-DEVELOPER",
        "TWS-C2S-DOS-MSN-ORG2-UNUSED-UNUSED-ORGMANAGER",
        "TWS-COMMERCIAL-UNUSED-UNUSED-VMWARE-TWS_SUPPORT-PROD-DEVELOPER",
        "TWS-COMMERCIAL-UNUSED-UNUSED-VMWARE-TWS_SUPPORT-ALL-DEVELOPER",
      ]
    }
  }

  test_users = {
    smoke_test = {
      common_name = "Smoke Test User"
      ou          = "People"
      roles = [
        "TWS-C2S-DOS-MSN-ORG1-MISSION1-PROD-DEVELOPER",
        "TWS-C2S-DOS-MSN-ORG1-MISSION2-all-DEVELOPER",
        "TWS-C2S-DOS-MSN-ORG2-UNUSED-UNUSED-ORGMANAGER",
        "TWS-COMMERCIAL-UNUSED-UNUSED-VMWARE-TWS_SUPPORT-PROD-DEVELOPER",
        "TWS-COMMERCIAL-UNUSED-UNUSED-VMWARE-TWS_SUPPORT-ALL-DEVELOPER",
      ]
    }

    portal_test_people = {
      common_name = "PortalEndToEndTestUser"
      ou          = "People"
      roles       = ["POPULATED_BY_TESTS"]
    }

    portal_test_apps_a = {
      common_name = "PortalEndToEndTestUser"
      ou          = "Applications"
      roles       = ["POPULATED_BY_TESTS"]
    }

    portal_test_apps_b = {
      common_name = "PortalEndToEndTestUser"
      ou          = "Applications"
      roles       = ["POPULATED_BY_TESTS"]
    }
  }

  // Test users are not placed in LDAP ahead of time.
  // Instead, the test suite will populate their LDAP entries. We just need to generate certs here.
  users_with_certs        = merge(local.test_users, local.smoke_test_users, var.users)
  users_with_ldap_entries = merge(local.smoke_test_users, var.users)
}

# Trusted issuer for all user certs

resource "tls_private_key" "issuer" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "issuer" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.issuer.private_key_pem

  subject {
    common_name  = "User PKI Root"
    organization = "VMware Tanzu Web Services"
  }
}

resource "tls_locally_signed_cert" "issuer" {
  cert_request_pem   = tls_cert_request.issuer.cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = tls_private_key.root.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root.cert_pem

  allowed_uses = [
    "digital_signature",
    "cert_signing",
  ]

  is_ca_certificate = true

  validity_period_hours = 8760 # 365 days

  early_renewal_hours = 4320 # 180 days
}

# User certificates

resource "tls_private_key" "user" {
  for_each  = local.users_with_certs
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "user" {
  for_each        = local.users_with_certs
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.user[each.key].private_key_pem

  subject {
    common_name         = each.value.common_name
    organization        = "VMware Tanzu Web Services"
    organizational_unit = each.value.ou
  }
}

resource "tls_locally_signed_cert" "user" {
  for_each           = local.users_with_certs
  cert_request_pem   = tls_cert_request.user[each.key].cert_request_pem
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = tls_private_key.issuer.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.issuer.cert_pem

  allowed_uses = [
    "digital_signature",
    "client_auth",
  ]

  validity_period_hours = 8760 # 365 days

  early_renewal_hours = 4320 # 180 days
}


output "users_with_ldap_entries" {
  value = local.users_with_ldap_entries
}

output "combined_users_with_certs" {
  value = {
    for key, value in local.users_with_certs : key => merge(value,
      {
        cert_pem        = tls_locally_signed_cert.user[key].cert_pem
        private_key_pem = tls_private_key.user[key].private_key_pem
      }
    )
  }
  sensitive = true
}