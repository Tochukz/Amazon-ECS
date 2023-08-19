terraform {
  backend "s3" {
    bucket = "sovtechchucks-terraform-states"
    key = "amazon-ecs/sample-solutions/ec2-cluster"
    region = "eu-west-2"
  }
  required_version = ">= 1.5.4"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "aws_region" current {}

data "aws_ecr_repository" "repo" {
  name = var.repository_name
}

locals {
  region = data.aws_region.current.name
}

data "aws_iam_policy_document" "ecs_agent" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [ "ec2.amazonaws.com" ]
    }
  }
}

resource "aws_vpc" "cluster_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true 
  enable_dns_support = true
  tags = {
    Name = "ClusterVPC"
  }
}

resource "aws_internet_gateway" "cluster_gateway" {
  vpc_id = aws_vpc.cluster_vpc.id
}

resource "aws_subnet" "public_subnet1" {
  vpc_id = aws_vpc.cluster_vpc.id 
  cidr_block = "10.0.128.0/19"
  map_public_ip_on_launch = true
  availability_zone = "${local.region}a"
}

resource "aws_subnet" "public_subnet2" {
  vpc_id = aws_vpc.cluster_vpc.id 
  cidr_block = "10.0.160.0/19"
  map_public_ip_on_launch = true
  availability_zone = "${local.region}b"
}

resource "aws_subnet" "private_subnet1" {
  vpc_id = aws_vpc.cluster_vpc.id 
  cidr_block = "10.0.192.0/19"
  map_public_ip_on_launch = false
  availability_zone = "${local.region}a"
}

resource "aws_subnet" "private_subnet2" {
  vpc_id = aws_vpc.cluster_vpc.id 
  cidr_block = "10.0.224.0/19"
  map_public_ip_on_launch = false
  availability_zone = "${local.region}b"
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.cluster_vpc.id 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cluster_gateway.id
  }
}

resource "aws_route_table_association" "public_route_subnet_assoc" {
  subnet_id = aws_subnet.public_subnet1.id 
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "ec2_security_group" {
  vpc_id = aws_vpc.cluster_vpc.id 
  ingress {
    from_port = 22 
    to_port = 22 
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  ingress {
    from_port = 443 
    to_port = 443 
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  egress {
    from_port = 0 
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_security_group" {
  vpc_id = aws_vpc.cluster_vpc.id 
  ingress {
    from_port = 3306
    to_port = 3306 
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Use specific limited IP range in production
    security_groups = [aws_security_group.ec2_security_group.id]
  }
  egress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ecs_agent" {
  name = "ECSAgent"
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json
}

resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_agent" {
  name = "ECSAgent"
  role = aws_iam_role.ecs_agent.name
}

resource "aws_key_pair" "ssh_key" {
  key_name = "Setup_Keypair"
  public_key = file("./keys/cluster.pub")
}

resource "aws_launch_configuration" "ecs_launch_config" {
  image_id = "ami-093fe7ed1e6dc726c" # ECS optimized AMI
  iam_instance_profile = aws_iam_instance_profile.ecs_agent.name
  security_groups = [ aws_security_group.ec2_security_group.id ]
  user_data = file("user-data.sh")
  instance_type = "t2.micro"
  associate_public_ip_address = true
  key_name = aws_key_pair.ssh_key.key_name
}

resource "aws_autoscaling_group" "cluster_scaling" {
  name = "ClusterAutoScaling"
  vpc_zone_identifier = [ aws_subnet.public_subnet1.id ]
  launch_configuration = aws_launch_configuration.ecs_launch_config.name
  desired_capacity = 2 
  min_size = 1 
  max_size = 10
  health_check_grace_period = 300 
  health_check_type = "EC2"
}

resource "aws_db_subnet_group" "db_subnet_group" {
  subnet_ids = [ 
    aws_subnet.private_subnet1.id,
    aws_subnet.private_subnet2.id 
  ]
}

resource "aws_db_instance" "mysql" {
  count = 0

  identifier = "mysql"
  allocated_storage         = 5
  backup_retention_period   = 2
  backup_window             = "01:00-01:30"
  maintenance_window        = "sun:03:00-sun:03:30"
  multi_az                  = false
  engine                    = "mysql"
  engine_version            = "5.7"
  instance_class            = "db.t2.micro"
  db_name                   = "ec2_cluster_db"
  username                  = "cluster_db_user"
  password                  = var.db_password
  port                      = "3306"
  db_subnet_group_name      = aws_db_subnet_group.db_subnet_group.id
  vpc_security_group_ids    = [aws_security_group.rds_security_group.id, aws_security_group.ec2_security_group.id]
  skip_final_snapshot       = true
  final_snapshot_identifier = "ec2-cluster-database-snapshot"
  publicly_accessible       = true 
}

# resource "aws_ecr_repository" "cluster_respositoy" {
#   name = "cluster-repository"
# }

resource "aws_ecs_cluster" "custom_cluster" {
  name = "ec2-cluster"
}

resource "aws_ecs_task_definition" "task_def" {
  family = "ec2-cluser"
  network_mode = "host"
  container_definitions = templatefile("task-definition.tftpl", { 
      REPOSITORY_URL = replace(data.aws_ecr_repository.repo.repository_url, "https://", ""),
      CONTAINER_NAME = var.container_name
  })
}

resource "aws_lb" "cluster_lb" {
  name               = "cluster-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.ec2_security_group.id  ]
  subnets            = [
    aws_subnet.public_subnet1.id,
    aws_subnet.public_subnet2.id
  ]
  enable_deletion_protection = false

  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.id
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = {
    Name = "Cluster_Application_Load_Balancer"
  }
}

resource "aws_lb_target_group" "cluster_lb_target_gp" {
  name        = "cluster-target-group"
  port        = 3000  # Replace with your container's exposed port
  protocol    = "HTTPS"
  target_type = "alb"
  vpc_id      = aws_vpc.cluster_vpc.id 
}

# resource "aws_lb_target_group_attachment" "cluster_group_attach" {
#   target_group_arn = aws_lb_target_group.cluster_lb_target_gp.arn
#   target_id = aws_lb.cluster_lb.arn
#   port = 3000
# }

resource "aws_lb_listener" "cluster_listener" {
  load_balancer_arn = aws_lb.cluster_lb.arn
  port = 3000
  protocol = "HTTPS"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.cluster_lb_target_gp.arn
  }
}

resource "aws_ecs_service" "cluster_service" {
  name = "cluster-service"
  cluster = aws_ecs_cluster.custom_cluster.id
  task_definition = aws_ecs_task_definition.task_def.arn 
  launch_type     = "EC2"
  desired_count = 2

  network_configuration {
    subnets = [aws_subnet.public_subnet1.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.cluster_lb_target_gp.arn
    container_name   = var.container_name 
    container_port   = 3000
  }
}