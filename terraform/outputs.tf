output "cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS Cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "EKS 클러스터의 인증서 정보"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL"
  value       = module.eks.cluster_oidc_issuer_url
}


output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "kubeconfig" {
  value = local_file.kubeconfig.content
}

output "eks_node_role_arn" {
  description = "EKS 워커 노드 IAM Role ARN"
  value       = aws_iam_role.eks_node_role.arn
}

output "eks_instance_profile_name" {
  description = "EKS 워커 노드 인스턴스 프로파일 이름"
  value       = aws_iam_instance_profile.eks_instance_profile.name
}

output "launch_template_id" {
  description = "EKS 노드용 Launch Template ID"
  value       = aws_launch_template.eks_node_lt.id
}

output "ssm_automation_role_arn" {
  value = aws_iam_role.ssm_automation_role.arn
}


output "ssm_doc_name" {
  value = aws_ssm_document.my_automation_doc.name
}

# output "eks_instance_ids" {
#   value = local.eks_instance_ids
# }