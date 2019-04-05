
resource "random_string" "redis_password" {
  length = 16
}

resource "aws_elasticache_subnet_group" "portal_cache_subnet_group" {
  subnet_ids = "${var.subnet_ids}"
  name = "${var.env_name}-portal-cache-subnet-group"
}

resource "aws_elasticache_replication_group" "portal_cache" {
  replication_group_id          = "${var.env_name}-portal-db"
  replication_group_description = "Cloud Portal Cache"
  node_type                     = "cache.r5.large"
  number_cache_clusters         = 3
  port                          = 6379
  security_group_ids = ["${var.security_group_id}"]
  subnet_group_name = "${aws_elasticache_subnet_group.portal_cache_subnet_group.name}"

  automatic_failover_enabled    = true
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token = "${random_string.redis_password.result}"
}
