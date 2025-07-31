
provider "aws" {
  region = "ap-northeast-2"
}


# 1. AWS Systems Manager 서비스 연결 역할 (Service-Linked Role) 생성
# resource "aws_iam_service_linked_role" "ssm_service_role" {
#   aws_service_name = "ssm.amazonaws.com"
#   description      = "Service-linked role for AWS Systems Manager"
# }

# 2. Automation 실행용 역할 (Lambda가 자동화 실행 시 사용할 역할)
resource "aws_iam_role" "ssm_automation_lambda_role" {
  name = "SSM-Automation-Lambda-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# 3. Lambda 역할에 필요한 권한 정책 연결
resource "aws_iam_role_policy_attachment" "ssm_lambda_basic_execution" {
  role       = aws_iam_role.ssm_automation_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "ssm_automation_execution_policy" {
  role       = aws_iam_role.ssm_automation_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}


module "ssm_endpoints" {
  source            = "./modules/vpc_endpoint"
  vpc_id            = module.vpc.vpc_id         # VPC 모듈의 출력값 사용
  subnet_ids        = module.vpc.private_subnets   # VPC 모듈의 출력값 사용
  vpc_cidr     = var.vpc_cidr
  region = var.region
  ec2_sg_ids = data.aws_network_interface.eks_node_primary_eni.security_groups
  service_names = [
    "com.amazonaws.${var.region}.ssm",
    "com.amazonaws.${var.region}.ec2messages",
    "com.amazonaws.${var.region}.ssmmessages"
  ]
  
}



resource "aws_launch_template" "eks_node_lt" {
  name_prefix   = "eks-node-lt-"
  image_id      = "ami-0d3144164828d1a0a"  # 직접 넣기
  instance_type = "t3.medium"

  user_data = base64encode(<<EOT
#!/bin/bash
yum install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
EOT
  )

  iam_instance_profile {
    name = aws_iam_instance_profile.eks_instance_profile.name
  }

  lifecycle {
    create_before_destroy = true
  }
}


# data "external" "eks_instance_ids" {
#  program = ["powershell", "-File", "${path.module}/scripts/get_instance_ids.ps1"]
#}
#
#locals {
#  eks_instance_ids = split(",", data.external.eks_instance_ids.result.ids)
#}



# resource "null_resource" "start_ssm_automation" {
#   count = length(data.aws_instances.eks_nodes.ids) > 0 ? length(data.aws_instances.eks_nodes.ids) : 0

#   provisioner "local-exec" {
#     command = "aws ssm start-automation-execution --document-name MyAutomationDocument --parameters AutomationAssumeRole=arn:aws:iam::116981781177:role/SSMAutomationRole,InstanceId=${data.aws_instances.eks_nodes.ids[count.index]} --region ap-northeast-2"
#   }

#   depends_on = [
#     aws_ssm_document.my_automation_doc,
#     aws_iam_role_policy_attachment.ssm_automation_role_attachment,
#     module.eks
#   ]
# }

resource "null_resource" "start_ssm_automation" {
  count = 1

  provisioner "local-exec" {
    command = <<EOT
      for instance_id in $(aws ec2 describe-instances --filters "Name=tag:Name,Values=default" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[].InstanceId" --output text); do
        aws ssm start-automation-execution --document-name MyAutomationDocument --parameters AutomationAssumeRole=arn:aws:iam::116981781177:role/SSMAutomationRole,InstanceId=$instance_id --region ap-northeast-2
      done
    EOT
  }

  depends_on = [
    aws_ssm_document.my_automation_doc,
    aws_iam_role_policy_attachment.ssm_automation_role_attachment,
    module.eks
  ]
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

    launch_template = {
        id      = aws_launch_template.eks_node_lt.id
        version = "$Latest"
    }

    iam_role_arn = aws_iam_role.eks_node_role.arn
    iam_role_additional_policies = {
      ssm = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

    tags = {
      some_key = "value"  # 클러스터 레벨 태그와 합쳐질 수 있음
    }
    node_group_tags = {
      Name = "eks-node-for-ssm"
    }
    }
  }

  enable_irsa = true
 
}


data "aws_instances" "eks_nodes" {
  filter {
    name   = "tag:Name"
    values = ["default"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  depends_on = [module.eks]
}

# 첫 번째 인스턴스의 기본 네트워크 인터페이스 ID 조회
data "aws_instance" "eks_node_0" {
  instance_id = data.aws_instances.eks_nodes.ids[0]
}

data "aws_network_interface" "eks_node_primary_eni" {
  id = data.aws_instance.eks_node_0.network_interface_id
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


data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# resource "aws_instance" "openvpn_ec2" {
#   ami           = "ami-05dbfca09fc71c807"                             # data.aws_ami.amazon_linux_2.id
#   instance_type = "t3.micro"
#   subnet_id     = module.vpc.public_subnets[0]
#   key_name      = "first-keypair" # SSH 접속용 키페어 이름

#   associate_public_ip_address = true

#   vpc_security_group_ids = [aws_security_group.openvpn_sg.id]

#   tags = {
#     Name = "OpenVPN-Server"
#   }

#   user_data = file("./scripts/install_openvpn.sh") 
  
#   lifecycle {
#     create_before_destroy = true
#   }
# }


# resource "aws_security_group" "openvpn_sg" {
#   name        = "openvpn-sg"
#   description = "Allow OpenVPN and SSH"
#   vpc_id      = module.vpc.vpc_id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = 1194
#     to_port     = 1194
#     protocol    = "udp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }