data "aws_vpc" "vpc" {
  id = "${var.vpc_id}"
}

resource "random_string" "redis_password" {
  length = 16
}

resource "aws_subnet" "portal_cache_subnets" {
  count             = "${length(var.availability_zones)}"
  vpc_id            = "${var.vpc_id}"
  cidr_block        = "${cidrsubnet(local.portal_cache_cidr, 2, count.index)}"
  availability_zone = "${element(var.availability_zones, count.index)}"

  tags = "${merge(var.tags, map("Name", "${var.env_name}-portal-cache-subnet${count.index}"))}"
}


resource "aws_elasticache_subnet_group" "portal_cache_subnet_group" {
  name = "${var.env_name}-portal-cache-subnet-group"
  description = "Portal Redis cache Subnet Group"

  subnet_ids = ["${aws_subnet.portal_cache_subnets.*.id}"]
}

resource "aws_security_group" "portal_cache_security_group" {
  name        = "portal_cache_security_group"
  description = "Portal Redis cache Security Group"
  vpc_id      = "${var.vpc_id}"

  ingress {
    cidr_blocks = ["${data.aws_vpc.vpc.cidr_block}"]
    protocol    = "tcp"
    from_port   = "6379"
    to_port     = "6379"
  }

  egress {
    cidr_blocks = ["${data.aws_vpc.vpc.cidr_block}"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  tags  = "${merge(var.tags, map("Name", "${var.env_name}-portal-cache-security-group"))}"
}

resource "aws_elasticache_replication_group" "portal_cache" {
  replication_group_id          = "${var.env_name}-portal-db"
  replication_group_description = "Cloud Portal Cache"
  node_type                     = "cache.r5.large"
  number_cache_clusters         = "${length(var.availability_zones)}"
  port                          = 6379
  subnet_group_name             = "${aws_elasticache_subnet_group.portal_cache_subnet_group.name}"
  security_group_ids            = ["${aws_security_group.portal_cache_security_group.id}"]
  availability_zones            = "${var.availability_zones}"
  automatic_failover_enabled    = true
  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = true
  auth_token                    = "${random_string.redis_password.result}"
}
