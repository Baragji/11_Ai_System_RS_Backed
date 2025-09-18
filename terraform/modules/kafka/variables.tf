variable "name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "kafka_version" {
  type = string
}

variable "client_sasl_users" {
  description = "List of users for SASL/SCRAM"
  type = list(object({
    username = string
    password = string
  }))
  sensitive = true
}

variable "kms_key_arn" {
  type = string
}

variable "broker_instance_type" {
  type    = string
  default = "kafka.m7g.large"
}

variable "broker_volume_size" {
  type    = number
  default = 1000
}

variable "tls_certificate_authority_arns" {
  type = list(string)
}

variable "cloudwatch_log_group" {
  type = string
}

variable "s3_log_bucket" {
  type = string
}
