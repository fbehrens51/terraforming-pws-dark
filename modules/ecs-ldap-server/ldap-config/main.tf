terraform {
  backend "s3" {
  }
}

data "terraform_remote_state" "infra" {
  backend = "s3"

  config = {
    bucket = "eagle-ci-blobs"
    key    = "ldap-server/infra.tfstate"
    region = "us-east-1"
  }
}

data "external" "pem-to-der" {
  for_each = data.terraform_remote_state.infra.outputs.combined_users_with_certs
  program  = ["bash", "${path.module}/pem-to-der.sh"]

  query = {
    pem = each.value.cert_pem
  }
}

data "external" "create-p12" {
  for_each = data.terraform_remote_state.infra.outputs.combined_users_with_certs
  program  = ["bash", "${path.module}/create-p12.sh"]

  query = {
    passphrase = each.value.common_name
    pem        = each.value.cert_pem
    key        = each.value.private_key_pem
  }
}

resource "aws_s3_bucket_object" "user_p12" {
  for_each       = data.terraform_remote_state.infra.outputs.combined_users_with_certs
  bucket         = "eagle-ci-blobs"
  key            = "ldap-user-keys/${each.key}.p12"
  content_base64 = data.external.create-p12[each.key].result.p12
}

output "user_ldifs" {
  value = templatefile("${path.module}/users.ldif.tpl", {
    users = { for key, value in data.terraform_remote_state.infra.outputs.users_with_ldap_entries : key => merge(value, {
      der = data.external.pem-to-der[key].result.der
    }) }
  })
}