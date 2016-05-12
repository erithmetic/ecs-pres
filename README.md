# Amazon ECS + Terraform Demo

A demo for a real-world web deployment

## Prerequisites

* (Terraform)[http://terraform.io]
* (AWS CLI)[https://docs.aws.amazon.com/cli/latest/userguide/installing.html]
* (ECS CLI)[https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ECS_CLI_installation.html]

## Running

```bash
export DEMO_ECS_ACCESS_KEY=mykey
export DEMO_ECS_SECRET_KEY=mysecret

# Create the ECS configuration on your AWS account
./terraform.sh

# Deploy the app as a task definition
./deploy.sh
```
