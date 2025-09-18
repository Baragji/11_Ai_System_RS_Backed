resource "aws_elasticache_parameter_group" "redis" {
  name   = "${var.name}-redis-7"
  family = "redis7"

  parameter {
    name  = "tls-auth-clients"
    value = "required"
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.name}-redis"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = "${var.name}-redis"
  description                   = "TLS protected Redis for shared state"
  node_type                     = var.node_type
  number_cache_clusters         = var.node_count
  parameter_group_name          = aws_elasticache_parameter_group.redis.name
  subnet_group_name             = aws_elasticache_subnet_group.redis.name
  security_group_ids            = var.security_group_ids
  multi_az_enabled              = true
  automatic_failover_enabled    = true
  transit_encryption_enabled    = true
  at_rest_encryption_enabled    = true
  kms_key_id                    = var.kms_key_arn
  auth_token                    = var.auth_token
  maintenance_window            = var.maintenance_window
  snapshot_window               = var.snapshot_window
  snapshot_retention_limit      = var.snapshot_retention_limit
  port                          = 6379
  apply_immediately             = false
  auto_minor_version_upgrade    = true
  engine_version                = "7.1"
  final_snapshot_identifier     = "${var.name}-redis-final"
  tags = {
    Name = "${var.name}-redis"
  }
}

output "primary_endpoint" {
  value = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "reader_endpoint" {
  value = aws_elasticache_replication_group.redis.reader_endpoint_address
}
