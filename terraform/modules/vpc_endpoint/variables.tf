variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "service_names" {
  type = list(string)
}


variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "region" {
  type        = string
}

variable "ec2_sg_ids" {
  type = list(string)
}