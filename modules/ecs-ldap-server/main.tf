terraform {
  backend "s3" {}
}

module "providers" {
  source = "../dark_providers"
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

resource aws_ecs_task_definition ldap {
  family                   = "ldap"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ldap.arn
  container_definitions = jsonencode([
    {
      name      = "openldap"
      image     = var.eagle-openldap-image
      essential = true
      cpu       = 256
      memory    = 512
      portMappings = [
        { containerPort = local.internal_ldap_port }
      ]
      secrets = [
        { name = "LDAP_ADMIN_PASSWORD", valueFrom = aws_secretsmanager_secret.ldap_password.arn },
      ]
    },
  ])

}

resource aws_ecs_service ldap {
  name            = "ldap"
  cluster         = aws_ecs_cluster.eagle.id
  task_definition = aws_ecs_task_definition.ldap.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private.*.id
    security_groups  = [aws_security_group.ldap.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ldap.arn
    container_name   = "openldap"
    container_port   = local.internal_ldap_port
  }
}


output ldap_domain {
  value = aws_lb.ldap.dns_name
}

output ldap_port {
  value = tostring(local.external_ldaps_port)
}

output ldap_password {
  value     = random_string.ldap_password.result
  sensitive = true
}

output ldap_ca_cert {
  value     = tls_self_signed_cert.root.cert_pem
  sensitive = true
}

output user_ca_cert {
  value = "${tls_self_signed_cert.root.cert_pem}\n${tls_locally_signed_cert.issuer.cert_pem}"
}
