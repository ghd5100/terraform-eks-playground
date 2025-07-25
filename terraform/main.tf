
provider "aws" {
  region = "ap-northeast-2"
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnet_ids      = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  eks_managed_node_groups = {
    default = {
      desired_size   = 1
      max_size       = 1
      min_size       = 1
      instance_types = ["t3.small"]
      iam_role_arn   = aws_iam_role.eks_node_role.arn
    }
  }

  enable_irsa = true
 
}

# EKS 클러스터 정보 조회
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

# 쿠버네티스 프로바이더 설정
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# aws-auth ConfigMap 직접 관리
# resource "kubernetes_config_map" "aws_auth" {
#   depends_on = [module.eks]

#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   data = {
#     mapRoles = yamlencode([
#       {
#         rolearn  = aws_iam_role.eks_node_role.arn
#         username = "system:node:{{EC2PrivateDNSName}}"
#         groups   = ["system:bootstrappers", "system:nodes"]
#       }
#     ])

#     mapUsers = yamlencode([
#       {
#         userarn  = aws_iam_user.admin_user.arn
#         username = "admin"
#         groups   = ["system:masters"]
#       }
#     ])
#   }
# }


module "vpc" {
  source = "./modules/vpc"

  vpc_name           = "eks-vpc"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]
}

locals {
  cluster_name = module.eks.cluster_name
  region       = var.region
  endpoint     = module.eks.cluster_endpoint
  ca_data      = module.eks.cluster_certificate_authority_data
}


resource "local_file" "kubeconfig" {
  depends_on = [module.eks]

  content = templatefile("${path.module}/kubeconfig.tpl", {
    cluster_name = local.cluster_name
    region       = local.region
    endpoint     = local.endpoint
    ca_data      = local.ca_data
  })
  
  filename = "${path.module}/kubeconfig_${local.cluster_name}.yaml"
}
