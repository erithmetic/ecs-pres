#!/bin/bash

set -euo pipefail

echo 'terraform plan \
  -var "aws_access_key=DEMO_ECS_ACCESS_KEY" \
  -var "aws_secret_key=$DEMO_ECS_SECRET_KEY"'

terraform plan \
  -var "aws_access_key=$DEMO_ECS_ACCESS_KEY" \
  -var "aws_secret_key=$DEMO_ECS_SECRET_KEY"

echo "Press enter to continue"
read

echo 'terraform apply \
  -var "aws_access_key=$DEMO_ECS_ACCESS_KEY" \
  -var "aws_secret_key=$DEMO_ECS_SECRET_KEY"'

terraform apply \
  -var "aws_access_key=$DEMO_ECS_ACCESS_KEY" \
  -var "aws_secret_key=$DEMO_ECS_SECRET_KEY"
