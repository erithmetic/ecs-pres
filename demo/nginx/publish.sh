#!/bin/bash

set -eou pipefail

IMAGE="ecs-demo-webapp-nginx"

docker tag -f $IMAGE dkastner/$IMAGE:latest
docker push dkastner/$IMAGE:latest
