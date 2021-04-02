terraform {
  backend "s3" {}
}

module "providers" {
  source = "../../dark_providers"
}

locals {
  // We use 443 here in order to escape the corporate firewall
  external_ldaps_port = 443
  internal_ldap_port  = 1389
}

resource random_string ldap_password {
  length = 16
}

resource "aws_secretsmanager_secret" "ldap_password" {
  name_prefix = "ldap_password"
}

resource "aws_secretsmanager_secret_version" "ldap_password" {
  secret_id     = aws_secretsmanager_secret.ldap_password.id
  secret_string = random_string.ldap_password.result
}

resource aws_ecs_cluster eagle {
  name = "eagle"
}


