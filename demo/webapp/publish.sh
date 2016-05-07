#!/bin/bash

set -eou pipefail

RAILS_IMAGE="ecs-demo-webapp-rails"
CABLE_IMAGE="ecs-demo-webapp-cable"

docker tag -f $RAILS_IMAGE dkastner/$RAILS_IMAGE:latest
docker push dkastner/$CABLE_IMAGE:latest

docker tag -f $RAILS_IMAGE dkastner/$RAILS_IMAGE:latest
docker push dkastner/$CABLE_IMAGE:latest
