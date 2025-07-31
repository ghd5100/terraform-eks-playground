#!/bin/bash

INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=default" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].InstanceId" --output text)

echo "{\"ids\": \"${INSTANCE_IDS}\"}"