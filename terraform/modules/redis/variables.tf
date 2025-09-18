variable "name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "kms_key_arn" {
  type = string
}

variable "auth_token" {
  type      = string
  sensitive = true
}

variable "node_type" {
  type    = string
  default = "cache.r6g.large"
}

variable "node_count" {
  type    = number
  default = 2
}

variable "maintenance_window" {
  type    = string
  default = "sun:06:00-sun:07:00"
}

variable "snapshot_window" {
  type    = string
  default = "07:00-08:00"
}

variable "snapshot_retention_limit" {
  type    = number
  default = 7
}
