#!/bin/bash

set -eou pipefail

RAILS_IMAGE="ecs-demo-webapp-rails"
CABLE_IMAGE="ecs-demo-webapp-cable"

docker build -f Dockerfile.rails -t $RAILS_IMAGE .
docker build -f Dockerfile.cable -t $CABLE_IMAGE .
