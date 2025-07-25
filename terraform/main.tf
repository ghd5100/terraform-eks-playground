
provider "aws" {
  region = "ap-northeast-2"
}

module "vpc" {
  source = "./modules/vpc"

  vpc_name           = "eks-vpc"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["ap-northeast-2a", "ap-northeast-2c"]
  private_subnets    = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets     = ["10.0.101.0/24", "10.0.102.0/24"]
}

module "eks" {
  source = "./modules/eks"

  cluster_name    = "my-cluster"
  cluster_version = "1.29"
  subnet_ids      = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id
}

locals {
  cluster_name = module.eks.cluster_name
  region       = "ap-northeast-2"
  endpoint     = module.eks.cluster_endpoint
  ca_data      = module.eks.cluster_certificate_authority_data
}

resource "local_file" "kubeconfig" {
  content = templatefile("${path.module}/kubeconfig.tpl", {
    cluster_name = local.cluster_name
    region       = local.region
    endpoint     = local.endpoint
    ca_data      = local.ca_data
  })

  filename = "${path.module}/kubeconfig_${local.cluster_name}"
}