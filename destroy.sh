#!/bin/bash

set -euo pipefail

echo 'terraform destroy \
  -var "aws_access_key=DEMO_ECS_ACCESS_KEY" \
  -var "aws_secret_key=$DEMO_ECS_SECRET_KEY"'

terraform destroy \
  -var "aws_access_key=$DEMO_ECS_ACCESS_KEY" \
  -var "aws_secret_key=$DEMO_ECS_SECRET_KEY"
