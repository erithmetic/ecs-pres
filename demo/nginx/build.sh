#!/bin/bash

set -eou pipefail

IMAGE="ecs-demo-webapp-nginx"

docker build -t $IMAGE .
