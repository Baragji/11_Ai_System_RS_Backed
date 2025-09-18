terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.15"
    }
  }
}

provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.aws_account_id]
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.main.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "main" {
  name = module.eks.cluster_name
}

module "vpc" {
  source               = "./modules/vpc"
  name                 = var.project_name
  cidr_block           = var.vpc_cidr
  azs                  = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  cache_subnet_cidrs    = var.cache_subnet_cidrs
  kafka_subnet_cidrs    = var.kafka_subnet_cidrs
}

module "rds" {
  source                = "./modules/rds"
  name                  = var.project_name
  db_subnet_group_name  = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.vpc.database_security_group_id]
  master_username       = var.rds_master_username
  master_password       = var.rds_master_password
  kms_key_arn           = var.kms_key_arn
  enhanced_monitoring_role_arn = var.rds_enhanced_monitoring_role_arn
}

module "redis" {
  source          = "./modules/redis"
  name            = var.project_name
  subnet_ids      = module.vpc.cache_subnet_ids
  security_group_ids = [module.vpc.cache_security_group_id]
  kms_key_arn     = var.kms_key_arn
  auth_token      = var.redis_auth_token
}

module "kafka" {
  source              = "./modules/kafka"
  name                = var.project_name
  subnet_ids          = module.vpc.kafka_subnet_ids
  security_group_ids  = [module.vpc.kafka_security_group_id]
  kafka_version       = var.kafka_version
  client_sasl_users   = var.kafka_client_users
  kms_key_arn         = var.kms_key_arn
  tls_certificate_authority_arns = var.kafka_tls_ca_arns
  cloudwatch_log_group = var.kafka_cloudwatch_log_group
  s3_log_bucket         = var.kafka_s3_log_bucket
}

module "eks" {
  source              = "./modules/eks"
  name                = var.project_name
  subnet_ids          = module.vpc.private_subnet_ids
  cluster_version     = var.eks_version
  cluster_role_arn    = var.eks_cluster_role_arn
  node_role_arn       = var.eks_node_role_arn
  kms_key_arn         = var.kms_key_arn
  node_instance_types = var.eks_node_instance_types
  desired_capacity    = var.eks_desired_capacity
  max_capacity        = var.eks_max_capacity
  min_capacity        = var.eks_min_capacity
  control_plane_security_group_id = module.vpc.eks_control_plane_security_group_id
  ssh_key_name                    = var.eks_ssh_key_name
  bastion_security_group_id       = var.bastion_security_group_id
  node_ami_id                     = var.eks_node_ami_id
}

module "vault" {
  source                 = "./modules/vault"
  name                   = var.project_name
  kms_key_arn            = var.kms_key_arn
  aws_region             = var.aws_region
  vault_tls_cert         = var.vault_tls_cert
  vault_tls_key          = var.vault_tls_key
  vault_tls_ca           = var.vault_tls_ca
}

module "otel_collector" {
  source                = "./modules/otel"
  name                  = var.project_name
  cluster_id            = module.eks.cluster_name
  collector_image       = var.otel_collector_image
  namespace             = var.observability_namespace
  jaeger_endpoint       = var.jaeger_otlp_endpoint
  prometheus_endpoint   = var.prometheus_remote_write_endpoint
  s3_backup_bucket_arn  = var.otel_s3_backup_bucket_arn
  aws_region            = var.aws_region
  kms_key_arn           = var.kms_key_arn
  iam_role_arn          = var.otel_iam_role_arn
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "rds_endpoint" {
  value = module.rds.endpoint
}

output "redis_primary_endpoint" {
  value = module.redis.primary_endpoint
}

output "kafka_bootstrap_brokers" {
  value = module.kafka.bootstrap_brokers
}
