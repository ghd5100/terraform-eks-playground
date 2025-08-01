resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = [
          "ec2.amazonaws.com",
          "eks.amazonaws.com"
        ]
      }
      Action = "sts:AssumeRole"
    }]
  })
}


resource "aws_iam_role_policy_attachment" "ssm_automation_attachment" {
  role       = aws_iam_role.ssm_automation_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess" # AWS 관리형 정책 중 하나
}


resource "aws_iam_role_policy_attachment" "ssm_managed_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  depends_on = [aws_iam_role.eks_node_role]
}


resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}




resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_readonly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


# 인스턴스 프로파일
resource "aws_iam_instance_profile" "eks_instance_profile" {
  name = "eks-node-instance-profile"
  role = aws_iam_role.eks_node_role.name
}


resource "aws_iam_policy" "ssm_portforward_policy" {
  name        = "SSMPortForwardPolicy"
  description = "Allow SSM Session and Port Forwarding"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:StartSession",
          "ssm:DescribeSessions",
          "ssm:GetSession",
          "ssm:TerminateSession",
          "ssm:ResumeSession",
          "ssm:StartPortForwardingSession"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_portforward_attach" {
  role       = aws_iam_role.ssm_automation_role.name
  policy_arn = aws_iam_policy.ssm_portforward_policy.arn
}