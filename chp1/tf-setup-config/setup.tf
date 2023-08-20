terraform {
  required_version = ">= 1.5.4"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "sovtechchucks-terraform-states"
    key = "amazon-ecs/chp1/setup-config"
    region = "eu-west-2"
  }
}

resource "aws_key_pair" "setup_keypair" {
  key_name = "Setup_Keypair"
  public_key = file("./keys/setup.pub")
}

# tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
resource "aws_vpc" "setup_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "SetupVCP"
  }
}

#@todo: Consider enabling flow_log for you vpc
# resource "aws_flow_log" {
# }

resource "aws_security_group" "setup_security_group" {
  vpc_id = aws_vpc.setup_vpc.id
  description = "Security group for EC2 launch type of ECS containers to permit HTTP/HTTPS and SSH access"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
    description = "Allow SSH access to the IPs in the ${var.ssh_allowed_cidr} range"
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [var.http_allowed_cidr]
    description = "Allow HTTP access to the IPs in the ${var.http_allowed_cidr} range"
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [var.http_allowed_cidr]
    description = "Allow HTTPS access to the IPs in the ${var.http_allowed_cidr} range"
  }
  tags = {
    Name = "SetupSecurityGroup"
  }
}

resource "aws_ecs_cluster" "simple_cluster" {
   name = "SimpleCluster"
}

resource "aws_iam_policy" "task_policy" {
  name = "SimpleTaskPolicy"
  policy = jsonencode({
    Version = "2012-010-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:CreateTopic",
          "sns:ListTopic",
          "sns:Publish"
        ]
        Resource = ["*"]
      }
    ]
  })
}
resource "aws_iam_role" "task_role" {
  name = "SimpleTaskRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "task_policy_attachment" {
  policy_arn = aws_iam_policy.task_policy.arn
  role = aws_iam_role.task_role.name
}

resource "aws_ecs_task_definition" "simple_task_def" {
  family = "simple_task_family"
  requires_compatibilities = ["EC2"]
  task_role_arn = aws_iam_role.task_role.arn
  network_mode = "awsvpc"
  cpu = 512 # 1vCPU = 1024
  memory = 1024
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture = "X86_64"
  }
  container_definitions = jsonencode([
    {
      name = "express-app"
      image = "665778208875.dkr.ecr.eu-west-2.amazonaws.com/express-app"
      #cpu = 10
      memory = 512
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 80
        } 
      ] 
      environment  = [
        {
           "name" : "NODE_ENV",
           "value":"development"
        },
        {
          "name": "JWT_SECRET",
          "value": var.jwt_secret
        }
      ]
    }
  ])
  volume {
    name      = "service-storage"
    host_path = "/ecs/service-storage"
  }
}