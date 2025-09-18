variable "name" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "collector_image" {
  type = string
}

variable "namespace" {
  type = string
}

variable "jaeger_endpoint" {
  type = string
}

variable "prometheus_endpoint" {
  type = string
}

variable "s3_backup_bucket_arn" {
  type = string
}

variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "kms_key_arn" {
  type = string
  default = ""
}

variable "iam_role_arn" {
  type = string
  default = ""
}

variable "helm_chart_version" {
  type    = string
  default = "0.69.0"
}

variable "resources" {
  type = any
  default = {
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
    requests = {
      cpu    = "250m"
      memory = "256Mi"
    }
  }
}

variable "tolerations" {
  type = any
  default = []
}
