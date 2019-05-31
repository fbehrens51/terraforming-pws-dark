output "redis_password" {
  value = "${aws_elasticache_replication_group.portal_cache.auth_token}"
}

output "redis_host" {
  value = "${aws_elasticache_replication_group.portal_cache.primary_endpoint_address}"
}

output "redis_port" {
  value = "${aws_elasticache_replication_group.portal_cache.port}"
}
