data "aws_vpc" "vpc" {
  id = var.vpc_id
}

resource "aws_security_group" "rds_security_group" {
  name        = "${var.env_name} rds security group"
  description = "RDS Instance Security Group"
  vpc_id      = var.vpc_id

  ingress {
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
    protocol    = "tcp"
    from_port   = var.db_port
    to_port     = var.db_port
  }

  egress {
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  # We changed how the name of the SG is determined.  Without the following
  # lifecycle, terraform will try to destroy the SG before creating the new
  # ones.  The destroy will fail because there is an RDS instance still using
  # the SG.
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      "Name" = "${var.env_name}-rds-security-group"
    },
  )
}

resource "random_string" "rds_password" {
  length  = 16
  special = false
}

resource "aws_db_instance" "rds" {
  allocated_storage       = 100
  instance_class          = var.rds_instance_class
  engine                  = var.engine
  engine_version          = var.engine_version
  identifier              = replace(var.env_name, " ", "-")
  username                = var.rds_db_username
  password                = random_string.rds_password.result
  db_subnet_group_name    = var.subnet_group_name
  publicly_accessible     = false
  vpc_security_group_ids  = [aws_security_group.rds_security_group.id]
  iops                    = 1000
  multi_az                = true
  skip_final_snapshot     = true
  backup_retention_period = 7
  apply_immediately       = true

  kms_key_id        = var.kms_key_id
  storage_encrypted = true

  tags = var.tags
}

