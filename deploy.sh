#!/bin/bash

set -euo pipefail

export AWS_ACCESS_KEY_ID=$DEMO_ECS_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$DEMO_ECS_SECRET_KEY

echo 'ecs-cli configure \
  --region us-east-1 \
  --access-key $DEMO_ECS_ACCESS_KEY \
  --secret-key $DEMO_ECS_SECRET_KEY \
  --cluster demo'

ecs-cli configure \
  --region us-east-1 \
  --access-key $DEMO_ECS_ACCESS_KEY \
  --secret-key $DEMO_ECS_SECRET_KEY \
  --cluster demo

set -v

# Create a new version of our ecscomose-webapp task definition using webapp.yml
ecs-cli compose -f demo/webapp.yml -p webapp create

# Update the ecscompose-service-webapp
# Note we have to use the aws command for this because ecs-cli doesn't properly
# update services once they're created
aws ecs update-service \
  --cluster demo \
  --service ecscompose-service-webapp \
  --task-definition ecscompose-webapp

# Bring up a database

# Populate the database
ecs-cli compose -f demo/rails.yml -p rails run rails "rake db:reset"

# Run 2 webapp services
ecs-cli compose -f demo/webapp.yml -p webapp service scale 2
