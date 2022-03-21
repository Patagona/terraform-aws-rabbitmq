variable "vpc_id" {
}

variable "ssh_key_name" {
}

variable "name_prefix" {
  description = "The full name of the created resources will be built as follows: {prefix}_{resource}_{postfix}"
}

variable "name_postfix" {
  description = "The full name of the created resources will be built as follows: {prefix}_{resource}_{postfix}"
}

variable "size" {
  description = "Number of RabbitMQ nodes"
  default     = 3
}

variable "subnet_ids" {
  description = "Subnets for RabbitMQ nodes"
  type        = list(string)
}

variable "nodes_additional_security_group_ids" {
  type    = list(string)
  default = []
}

variable "elb_additional_security_group_ids" {
  type    = list(string)
  default = []
}

variable "instance_type" {
  default = "m5.large"
}

variable "instance_volume_type" {
  default = "standard"
}

variable "instance_volume_size" {
  default = "0"
}

variable "instance_volume_iops" {
  default = "0"
}
variable "instance_volume_throughput" {
  default = "0"
}

variable "service_tag" {
}

variable "git_key" {}
