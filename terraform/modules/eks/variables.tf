variable "name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "cluster_version" {
  type = string
}

variable "cluster_role_arn" {
  type    = string
  default = ""
}

variable "node_role_arn" {
  type    = string
  default = ""
}

variable "node_instance_types" {
  type = list(string)
}

variable "desired_capacity" {
  type = number
}

variable "max_capacity" {
  type = number
}

variable "min_capacity" {
  type = number
}

variable "kms_key_arn" {
  type = string
}

variable "control_plane_security_group_id" {
  type = string
  default = ""
}

variable "service_ipv4_cidr" {
  type    = string
  default = "172.20.0.0/16"
}

variable "ssh_key_name" {
  type = string
}

variable "bastion_security_group_id" {
  type = string
}

variable "node_ami_id" {
  type = string
}
