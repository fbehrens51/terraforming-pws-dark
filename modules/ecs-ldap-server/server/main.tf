terraform {
  backend "s3" {}
}

module "providers" {
  source = "../../dark_providers"
}

variable "eagle-openldap-image" {}

locals {
  // We use 443 here in order to escape the corporate firewall
  external_ldaps_port = 443
  internal_ldap_port  = 1389
}


data "terraform_remote_state" "infra" {
  backend = "s3"

  config = {
    bucket = "eagle-ci-blobs"
    key    = "ldap-server/infra.tfstate"
    region = "us-east-1"
  }
}

resource "aws_ecs_task_definition" "ldap" {
  family                   = "ldap"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = data.terraform_remote_state.infra.outputs.ecs_execution_role
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
        { name = "LDAP_ADMIN_PASSWORD", valueFrom = data.terraform_remote_state.infra.outputs.ldap_password_secret },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-region"        = "us-east-1"
          "awslogs-group"         = aws_cloudwatch_log_group.ldap-logs.name
          "awslogs-stream-prefix" = "ldap"
        }
      }
    },
  ])

}

resource "aws_cloudwatch_log_group" "ldap-logs" {
  name              = "LDAP-ECS"
  retention_in_days = 30
}

resource "aws_ecs_service" "ldap" {
  name            = "ldap"
  cluster         = data.terraform_remote_state.infra.outputs.ecs_cluster_id
  task_definition = aws_ecs_task_definition.ldap.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.terraform_remote_state.infra.outputs.private_subnets
    security_groups  = [data.terraform_remote_state.infra.outputs.ldap_security_group]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = data.terraform_remote_state.infra.outputs.ldap_target_group
    container_name   = "openldap"
    container_port   = local.internal_ldap_port
  }
}

