# modules/eks/variables.tf

variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
}

variable "cluster_version" {
  description = "EKS 클러스터 버전"
  type        = string
  default     = "1.29"
}

variable "subnet_ids" {
  description = "EKS 클러스터가 사용할 서브넷 ID 목록 (보통 private 서브넷)"
  type        = list(string)
}

variable "vpc_id" {
  description = "EKS 클러스터가 속할 VPC ID"
  type        = string
}