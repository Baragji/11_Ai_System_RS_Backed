resource "aws_db_parameter_group" "postgres" {
  name        = "${var.name}-postgres14"
  family      = "postgres14"
  description = "Postgres parameter group with SSL enforcement"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
}

resource "aws_db_instance" "postgres" {
  identifier             = "${var.name}-postgres"
  engine                 = "postgres"
  engine_version         = "14.10"
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  max_allocated_storage  = var.max_allocated_storage
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  username               = var.master_username
  password               = var.master_password
  storage_encrypted      = true
  kms_key_id             = var.kms_key_arn
  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window
  multi_az               = true
  deletion_protection    = true
  auto_minor_version_upgrade = true
  publicly_accessible        = false
  iam_database_authentication_enabled = true
  performance_insights_enabled        = true
  performance_insights_kms_key_id     = var.kms_key_arn
  monitoring_interval                = 60
  monitoring_role_arn                = var.enhanced_monitoring_role_arn
  parameter_group_name               = aws_db_parameter_group.postgres.name
  apply_immediately                  = false
  copy_tags_to_snapshot              = true
  skip_final_snapshot                = false
  final_snapshot_identifier          = "${var.name}-postgres-final"
  tags = {
    Name = "${var.name}-postgres"
  }
}

output "endpoint" {
  value = aws_db_instance.postgres.address
}

output "port" {
  value = aws_db_instance.postgres.port
}
