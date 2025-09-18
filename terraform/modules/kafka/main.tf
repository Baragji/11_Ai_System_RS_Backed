locals {
  user_map = { for user in var.client_sasl_users : user.username => user.password }
}

resource "aws_secretsmanager_secret" "scram" {
  for_each = local.user_map
  name     = "${var.name}/msk/${each.key}"
  kms_key_id = var.kms_key_arn
}

resource "aws_secretsmanager_secret_version" "scram" {
  for_each      = local.user_map
  secret_id     = aws_secretsmanager_secret.scram[each.key].id
  secret_string = jsonencode({ username = each.key, password = each.value })
}

resource "aws_msk_configuration" "this" {
  name              = "${var.name}-msk-config"
  kafka_versions    = [var.kafka_version]
  server_properties = <<PROPERTIES
auto.create.topics.enable=false
min.insync.replicas=2
unclean.leader.election.enable=false
log.retention.hours=168
PROPERTIES
}

resource "aws_msk_cluster" "this" {
  cluster_name           = "${var.name}-msk"
  kafka_version          = var.kafka_version
  number_of_broker_nodes = length(var.subnet_ids)
  enhanced_monitoring    = "PER_TOPIC_PER_PARTITION"
  configuration_info {
    arn      = aws_msk_configuration.this.arn
    revision = aws_msk_configuration.this.latest_revision
  }

  broker_node_group_info {
    instance_type   = var.broker_instance_type
    client_subnets  = var.subnet_ids
    security_groups = var.security_group_ids
    storage_info {
      ebs_storage_info {
        volume_size = var.broker_volume_size
      }
    }
  }

  client_authentication {
    sasl {
      scram = true
      iam   = false
    }
    tls {
      certificate_authority_arns = var.tls_certificate_authority_arns
    }
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = var.kms_key_arn
    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = var.cloudwatch_log_group
      }
      s3 {
        enabled = true
        bucket  = var.s3_log_bucket
        prefix  = "msk"
      }
    }
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = true
      }
    }
  }

tags = {
    Name = "${var.name}-msk"
  }
}

resource "aws_msk_scram_secret_association" "this" {
  cluster_arn = aws_msk_cluster.this.arn
  secret_arn_list = [for secret in aws_secretsmanager_secret.scram : secret.arn]
}

output "bootstrap_brokers" {
  value = aws_msk_cluster.this.bootstrap_brokers_sasl_scram
}
