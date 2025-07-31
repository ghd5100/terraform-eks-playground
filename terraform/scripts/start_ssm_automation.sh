#!/bin/bash
set -e

INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=default" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].InstanceId" --output text)

for instance_id in $INSTANCE_IDS; do
  aws ssm start-automation-execution \
    --document-name MyAutomationDocument \
    --parameters AutomationAssumeRole=arn:aws:iam::116981781177:role/SSMAutomationRole,InstanceId=$instance_id \
    --region ap-northeast-2
done