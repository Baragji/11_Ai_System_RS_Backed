variable "name" {
  type = string
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "cidr_block" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "database_subnet_cidrs" {
  type = list(string)
}

variable "cache_subnet_cidrs" {
  type = list(string)
}

variable "kafka_subnet_cidrs" {
  type = list(string)
}
