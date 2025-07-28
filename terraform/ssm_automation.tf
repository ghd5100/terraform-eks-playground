resource "aws_iam_role" "ssm_automation_role" {
  name = "SSMAutomationRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ssm.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_automation_role_attachment" {
  role       = aws_iam_role.ssm_automation_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_ssm_document" "my_automation_doc" {
  name          = "MyAutomationDocument"
  document_type = "Automation"
  content = jsonencode({
    schemaVersion = "0.3"
    description   = "Stop EC2 instance"
    parameters = {
      InstanceId = {
        type        = "String"
        description = "EC2 Instance ID"
      }
      AutomationAssumeRole = {
        type        = "String"
        description = "IAM Role ARN for Automation"
      }
    }
    mainSteps = [
      {
        name   = "stopInstance"
        action = "aws:changeInstanceState"
        inputs = {
          InstanceIds  = ["{{ InstanceId }}"]
          DesiredState = "stopped"
        }
      }
    ]
  })
}


