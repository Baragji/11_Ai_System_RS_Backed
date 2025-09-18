variable "name" {
  type = string
}

variable "db_subnet_group_name" {
  type = string
  default = ""
}

variable "vpc_security_group_ids" {
  type = list(string)
}

variable "master_username" {
  type      = string
  sensitive = true
}

variable "master_password" {
  type      = string
  sensitive = true
}

variable "kms_key_arn" {
  type = string
}

variable "instance_class" {
  type    = string
  default = "db.m6g.large"
}

variable "allocated_storage" {
  type    = number
  default = 100
}

variable "max_allocated_storage" {
  type    = number
  default = 1000
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "backup_window" {
  type    = string
  default = "04:00-05:00"
}

variable "maintenance_window" {
  type    = string
  default = "sun:05:00-sun:06:00"
}

variable "enhanced_monitoring_role_arn" {
  type = string
}
