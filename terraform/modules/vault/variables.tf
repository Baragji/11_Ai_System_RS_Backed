variable "name" {
  type = string
}

variable "namespace" {
  type    = string
  default = "vault"
}

variable "helm_chart_version" {
  type    = string
  default = "0.25.0"
}

variable "vault_image_tag" {
  type    = string
  default = "1.15.6"
}

variable "kms_key_arn" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "audit_storage_class" {
  type    = string
  default = "gp3"
}

variable "server_resources" {
  type = any
  default = {
    limits = {
      cpu    = "500m"
      memory = "1Gi"
    }
    requests = {
      cpu    = "250m"
      memory = "512Mi"
    }
  }
}

variable "vault_tls_cert" {
  type      = string
  sensitive = true
}

variable "vault_tls_key" {
  type      = string
  sensitive = true
}

variable "vault_tls_ca" {
  type      = string
  sensitive = true
}
