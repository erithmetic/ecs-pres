# Basic provider setup connect us into AWS
# 
provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "us-east-1"
}

# Virtual private cloud (VPC) that will host our ECS instances
# 
resource "aws_vpc" "ecs" {
  cidr_block = "10.0.0.0/24"
}
resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.ecs.id}"
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
}
resource "aws_internet_gateway" "public" {
  vpc_id = "${aws_vpc.ecs.id}"
}
# This lets us SSH into our instances
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.ecs.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.public.id}"
  }
}
resource "aws_route_table_association" "public" {
  subnet_id = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

# Security group to allow public HTTP into our VPC
#
resource "aws_security_group" "webapp" {
  name = "ecs-sg"
  vpc_id = "${aws_vpc.ecs.id}"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Load balancer (ELB) that routes public HTTP requests to our ECS webapp service
#
resource "aws_elb" "webapp" {
  name = "demo-webapp-elb"

  security_groups = ["${aws_security_group.webapp.id}"]
  subnets = ["${aws_subnet.public.id}"]

  # Forward public port 80 to the instance's port 80
  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    # Health check path needs to respond with 200
    target = "HTTP:80/"
    # When using webapp.yml, health check needs to point to login page cuz /
    # returns HTTP 302
    # target = "HTTP:80/session/new"
    interval = 10
    timeout = 3
  }
}

# IP and Route53 domain used for web load balancing - mapped to our ELB above
#
# Public IP for our cluster (Elastic IP)
resource "aws_eip" "awesomedemo" {
  vpc = true
}
resource "aws_route53_record" "awesomedemo" {
  name = "awesomedemo.click"

  # Normally you could use terraform to define a Route53 zone, but I'm using a
  # hardcoded ID from a zone AWS created for me at domain registration time
  zone_id = "ZM15PSKU9TSYD"
  type = "A"
  set_identifier = "awesomedemo-primary"                                        
  failover = "PRIMARY"

  # Because we're pointing to an ELB, this needs to be an ALIAS record with     
  # the appropriate `name` and `zone_id` values from the ELB.                   
  alias {
    name = "${aws_elb.webapp.dns_name}"                                    
    zone_id = "${aws_elb.webapp.zone_id}"                                  
    # Check the ELB's health.  If it's unhealthy, fail over to our              
    # SECONDARY record.
    evaluate_target_health = true                                               
  } 
}

# Launch configuration - defines what kind of instances to spin up for our
# cluster. Find the latest AMI listing at
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html
#
resource "aws_launch_configuration" "demo" {
  name = "default"
  # This image id is for the latest Amazon Linux that auto-starts ecs-agent
  # amzn-ami-2016.03.a-amazon-ecs-optimized
  image_id = "ami-67a3a90d"
  instance_type = "m3.medium"
  security_groups = ["${aws_security_group.webapp.id}"]
  associate_public_ip_address = true
  iam_instance_profile = "${aws_iam_instance_profile.ecs.name}"

  # Optional keypair for sshing into instances
  key_name = "ecs"

  # Tell this instance which cluster to join
  user_data = "#!/bin/bash\necho ECS_CLUSTER=demo >> /etc/ecs/ecs.config"
}

# Autoscaling group - defines how many servers to spin up for our launch config
#
resource "aws_autoscaling_group" "demo" {
  name = "default"
  launch_configuration = "${aws_launch_configuration.demo.name}"
  min_size = 2
  max_size = 3
  desired_capacity = 2

  vpc_zone_identifier = ["${aws_subnet.public.id}"]
  health_check_type = "EC2"
}

# ECS container instance IAM role - identifies ecs agents as belonging to us
# and allows them to tell our ELB that they can serve web stuff
resource "aws_iam_role" "ecs_instance_role" {
  name = "ecsInstanceRole"
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": { "Service": ["ecs.amazonaws.com", "ec2.amazonaws.com"] },
      "Effect": "Allow"
    }
  ]
}
EOF
}
resource "aws_iam_role" "ecs_service_role" {
  name = "ecsServiceRole"
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": { "Service": ["ecs.amazonaws.com", "ec2.amazonaws.com"] },
      "Effect": "Allow"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "ecs_instance_role_policy" {
  name = "ecsInstanceRolePolicy"
  role = "${aws_iam_role.ecs_instance_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "ecs_service_role_policy" {
  name = "ecsServiceRolePolicy"
  role = "${aws_iam_role.ecs_service_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "ec2:Describe*",
        "ec2:AuthorizeSecurityGroupIngress"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}
resource "aws_iam_instance_profile" "ecs" {
  name = "ecs-instance-profile"
  path = "/"
  roles = ["${aws_iam_role.ecs_instance_role.name}"]
}

# Cluster 
#
resource "aws_ecs_cluster" "demo" {
  name = "demo"
}

## The following task definition and service are placeholders

# Task definition - a dummy task just to get our service up
# Normally, ecs-cli creates these for us, but we need a default task to get
# these configs rolling and assign an ELB to our webapp service
#
resource "aws_ecs_task_definition" "terraform_placeholder" {
  # Family is basically just the "name," which needs to match the format used by
  # `ecs-cli compose`
  family = "ecscompose-webapp"
  container_definitions = "${file("${path.module}/terraform_placeholder.json")}"
}

# Service - we need to associate our webapp service with the public HTTP load
# balancer
#
resource "aws_ecs_service" "webapp" {
  # This name needs to match the format used by `ecs-cli compose`
  name = "ecscompose-service-webapp"
  cluster = "${aws_ecs_cluster.demo.name}"                                      
  task_definition = "${aws_ecs_task_definition.terraform_placeholder.arn}"
  desired_count = 1

  # The IAM that lets us notify our ELB that we're up
  iam_role = "${aws_iam_role.ecs_service_role.name}"
                                                                                
  # Hook up to our load balancer.
  load_balancer {                                                      
    elb_name = "${aws_elb.webapp.id}"

    # This needs to be set to the name of the container that listens on port 80
    container_name = "nginx"
    container_port = 80
  }
}
