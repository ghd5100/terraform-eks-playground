variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default = "my-eks-cluster"
}

# variable "cluster_version" {
#   description = "EKS Cluster Version"
#   type        = string
#   default     = "1.28"  # 기본값 지정 가능
# }

variable "subnet_ids" {
  description = "EKS 클러스터가 사용할 서브넷 ID 리스트"
  type        = list(string)
  default = [ "10.0.1.0/24", "10.0.2.0/24" ]
}


variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"  # 원하면 기본값 설정 가능
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}