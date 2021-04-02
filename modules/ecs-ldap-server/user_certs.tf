
locals {
  default_users = {
    smoke_test = {
      common_name = "Smoke Test User"
      ou          = "People"
      roles = [
        "TWS-C2S-DOS-MSN-ORG1-MISSION1-PROD-DEVELOPER",
        "TWS-C2S-DOS-MSN-ORG1-MISSION2-all-DEVELOPER",
        "TWS-C2S-DOS-MSN-ORG2-UNUSED-UNUSED-ORGMANAGER",
      ]
    }

    portal_test_people = {
      common_name = "PortalEndToEndTestUser"
      ou          = "People"
      roles       = []
    }

    portal_test_apps_a = {
      common_name = "PortalEndToEndTestUser"
      ou          = "Applications"
      roles       = []
    }

    portal_test_apps_b = {
      common_name = "PortalEndToEndTestUser"
      ou          = "Applications"
      roles       = []
    }
  }

  users = merge(local.default_users, var.users)
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
  for_each  = local.users
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "tls_cert_request" "user" {
  for_each        = local.users
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.user[each.key].private_key_pem

  subject {
    common_name         = each.value.common_name
    organization        = "VMware Tanzu Web Services"
    organizational_unit = each.value.ou
  }
}

resource "tls_locally_signed_cert" "user" {
  for_each           = local.users
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

data "external" "pem-to-der" {
  for_each = local.users
  program  = ["bash", "${path.module}/pem-to-der.sh"]

  query = {
    pem = tls_locally_signed_cert.user[each.key].cert_pem
  }
}

data "external" "create-p12" {
  for_each = local.users
  program  = ["bash", "${path.module}/create-p12.sh"]

  query = {
    passphrase = each.value.common_name
    pem        = tls_locally_signed_cert.user[each.key].cert_pem
    key        = tls_private_key.user[each.key].private_key_pem
  }
}

data "null_data_source" "ldifs" {
  for_each = local.users
  inputs = {
    ldif = templatefile("${path.module}/users.ldif.tpl", {
      user = each.value,
      der  = data.external.pem-to-der[each.key].result.der,
    })
  }
}

resource aws_s3_bucket_object user_p12 {
  for_each       = local.users
  bucket         = "eagle-ci-blobs"
  key            = "ldap-user-keys/${each.key}.p12"
  content_base64 = data.external.create-p12[each.key].result.p12
}

output "user_ldifs" {
  value = join("\n", [for key in keys(local.users) : data.null_data_source.ldifs[key].outputs.ldif])
}


