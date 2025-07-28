resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "vpc-endpoint-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = var.vpc_id

#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = [var.vpc_cidr]
#   }

  ingress {
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  security_groups = var.ec2_sg_ids # EC2 인스턴스 노드 그룹 보안 그룹 ID
    }

  ingress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["10.8.0.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_vpc_endpoint" "this" {
#   for_each = toset(var.service_names)

#   vpc_id              = var.vpc_id
#   service_name        = each.value
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = var.subnet_ids
#   private_dns_enabled = false
#   security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
# }


resource "aws_vpc_endpoint" "ssm_endpoints" {
  for_each = toset(var.service_names)

  vpc_id            = var.vpc_id
  service_name      = each.value
  vpc_endpoint_type = "Interface"
  subnet_ids        = var.subnet_ids
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = false #false
}