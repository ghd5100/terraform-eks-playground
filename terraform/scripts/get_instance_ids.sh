#!/bin/bash
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=eks-node-for-ssm" "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].InstanceId" --output json)

echo "{\"ids\": $INSTANCE_IDS}"