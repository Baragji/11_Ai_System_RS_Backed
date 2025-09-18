variable "project_name" {
  type        = string
  description = "Project identifier used for tagging and naming resources"
}

variable "aws_region" {
  type        = string
  description = "AWS region for deployment"
}

variable "aws_account_id" {
  type        = string
  description = "AWS account ID to guard against misconfiguration"
}

variable "vpc_cidr" {
  type        = string
  description = "Primary CIDR block for the VPC"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones to span subnets across"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets"
}

variable "database_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for dedicated database subnets"
}

variable "cache_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for ElastiCache subnets"
}

variable "kafka_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for MSK broker subnets"
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the AWS KMS key used for encryption at rest"
}

variable "redis_auth_token" {
  type        = string
  description = "Auth token enforcing TLS client authentication for Redis"
  sensitive   = true
}

variable "rds_master_username" {
  type        = string
  description = "Master username for the PostgreSQL database"
  sensitive   = true
}

variable "rds_master_password" {
  type        = string
  description = "Master password for the PostgreSQL database"
  sensitive   = true
}

variable "rds_enhanced_monitoring_role_arn" {
  type        = string
  description = "IAM role ARN used for RDS enhanced monitoring"
}

variable "kafka_version" {
  type        = string
  description = "Kafka version for the MSK cluster"
  default     = "3.6.0"
}

variable "kafka_client_users" {
  description = "List of SASL/SCRAM users to provision for MSK"
  type = list(object({
    username = string
    password = string
  }))
  sensitive = true
}

variable "kafka_tls_ca_arns" {
  type        = list(string)
  description = "Certificate authority ARNs for Kafka TLS client validation"
}

variable "kafka_cloudwatch_log_group" {
  type        = string
  description = "CloudWatch log group name for MSK broker logs"
}

variable "kafka_s3_log_bucket" {
  type        = string
  description = "S3 bucket used for MSK broker log archiving"
}

variable "eks_version" {
  type        = string
  description = "Desired Kubernetes version for EKS"
  default     = "1.28"
}

variable "eks_cluster_role_arn" {
  type        = string
  description = "IAM role ARN for the EKS control plane"
}

variable "eks_node_role_arn" {
  type        = string
  description = "IAM role ARN assumed by EKS managed node groups"
}

variable "eks_node_instance_types" {
  type        = list(string)
  description = "Instance types for EKS worker nodes"
}

variable "eks_desired_capacity" {
  type        = number
  description = "Desired number of EKS worker nodes"
}

variable "eks_max_capacity" {
  type        = number
  description = "Maximum number of EKS worker nodes"
}

variable "eks_min_capacity" {
  type        = number
  description = "Minimum number of EKS worker nodes"
}

variable "eks_ssh_key_name" {
  type        = string
  description = "Name of the EC2 SSH key pair for EKS nodes"
}

variable "bastion_security_group_id" {
  type        = string
  description = "Security group ID for the bastion host that manages nodes"
}

variable "eks_node_ami_id" {
  type        = string
  description = "AMI ID used for EKS managed node groups"
}

variable "otel_collector_image" {
  type        = string
  description = "Container image for the OpenTelemetry collector"
  default     = "otel/opentelemetry-collector-contrib:0.93.0"
}

variable "otel_iam_role_arn" {
  type        = string
  description = "IAM role ARN granting the collector access to export destinations"
}

variable "observability_namespace" {
  type        = string
  description = "Kubernetes namespace for observability components"
  default     = "observability"
}

variable "jaeger_otlp_endpoint" {
  type        = string
  description = "OTLP gRPC endpoint for Jaeger collector"
  default     = "jaeger-collector.observability.svc.cluster.local:4317"
}

variable "prometheus_remote_write_endpoint" {
  type        = string
  description = "Prometheus remote write URL for metrics fan-out"
  default     = "https://prometheus.example.com/api/v1/write"
}

variable "otel_s3_backup_bucket_arn" {
  type        = string
  description = "S3 bucket ARN for telemetry export backups"
}

variable "vault_tls_cert" {
  type        = string
  description = "Base64 encoded Vault server certificate"
  sensitive   = true
}

variable "vault_tls_key" {
  type        = string
  description = "Base64 encoded Vault server key"
  sensitive   = true
}

variable "vault_tls_ca" {
  type        = string
  description = "Base64 encoded CA certificate trusted by Vault"
  sensitive   = true
}
