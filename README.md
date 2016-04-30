# Amazon ECS + Terraform Demo

A demo for a real-world web deployment

## Prerequisites

* (Terraform)[http://terraform.io]
* (ECS CLI)[https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html]

## Running

```bash
export DEMO_ECS_ACCESS_KEY=mykey
export DEMO_ECS_SECRET_KEY=mysecret

# Create the ECS configuration on your AWS account
./terraform.sh

# Deploy the app
cd demo
ecs-cli compose -f webapp.yml -p webapp create
ecs-cli compose -f webapp.yml -p webapp run rails rake db:reset
ecs-cli compose -f webapp.yml -p webapp scale 2
```
