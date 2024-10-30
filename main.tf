terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.region_1
}

provider "aws" {
  alias  = "region_1"
  region = var.region_1
}

provider "aws" {
  alias  = "region_2"
  region = var.region_2
}

resource "aws_vpc" "vpc_region_1" {
  provider   = aws.region_1
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc_region_1"
  }
}

resource "aws_vpc" "vpc_region_2" {
  provider   = aws.region_2
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "vpc_region_2"
  }
}

resource "aws_subnet" "subnet_region_1a" {
  provider                = aws.region_1
  vpc_id                  = aws_vpc.vpc_region_1.id
  cidr_block              = var.az_1_cidrs[0]
  availability_zone       = var.az_1[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet_region_1a"
  }
}

resource "aws_subnet" "subnet_region_1b" {
  provider                = aws.region_1
  vpc_id                  = aws_vpc.vpc_region_1.id
  cidr_block              = var.az_1_cidrs[1]
  availability_zone       = var.az_1[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet_region_1b"
  }
}

resource "aws_subnet" "subnet_region_2a" {
  provider                = aws.region_2
  vpc_id                  = aws_vpc.vpc_region_2.id
  cidr_block              = var.az_2_cidrs[0]
  availability_zone       = var.az_2[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet_region_2a"
  }
}

resource "aws_subnet" "subnet_region_2b" {
  provider                = aws.region_2
  vpc_id                  = aws_vpc.vpc_region_2.id
  cidr_block              = var.az_2_cidrs[1]
  availability_zone       = var.az_2[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet_region_2b"
  }
}

resource "aws_internet_gateway" "igw_region_1" {
  provider = aws.region_1
  vpc_id   = aws_vpc.vpc_region_1.id

  tags = {
    Name = "igw_region_1"
  }
}

resource "aws_internet_gateway" "igw_region_2" {
  provider = aws.region_2
  vpc_id   = aws_vpc.vpc_region_2.id

  tags = {
    Name = "igw_region_2"
  }
}

resource "aws_route_table" "route_region_1" {
  provider = aws.region_1
  vpc_id   = aws_vpc.vpc_region_1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_region_1.id
  }
}

resource "aws_route_table" "route_region_2" {
  provider = aws.region_2
  vpc_id   = aws_vpc.vpc_region_2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_region_2.id
  }
}

resource "aws_route_table_association" "a_region_1a" {
  provider       = aws.region_1
  subnet_id      = aws_subnet.subnet_region_1a.id
  route_table_id = aws_route_table.route_region_1.id
}

resource "aws_route_table_association" "a_region_1b" {
  provider       = aws.region_1
  subnet_id      = aws_subnet.subnet_region_1b.id
  route_table_id = aws_route_table.route_region_1.id
}

resource "aws_route_table_association" "a_region_2a" {
  provider       = aws.region_2
  subnet_id      = aws_subnet.subnet_region_2a.id
  route_table_id = aws_route_table.route_region_2.id
}

resource "aws_route_table_association" "a_region_2b" {
  provider       = aws.region_2
  subnet_id      = aws_subnet.subnet_region_2b.id
  route_table_id = aws_route_table.route_region_2.id
}

data "aws_ami" "latest_amazon_linux" {
  provider    = aws.region_1
  most_recent = true

  owners = ["137112412989"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "web_server_sg" {
  provider    = aws.region_1
  vpc_id      = aws_vpc.vpc_region_1.id
  name        = "web_server_sg"
  description = "Allow HTTP and SSH traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["99.234.137.42/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "web_server_lt" {
  name          = "web_server_launch_template"
  image_id      = data.aws_ami.latest_amazon_linux.id
  instance_type = "t2.micro"
  key_name      = "main-key"

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "web_server_instance"
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_server_sg.id]
  }
}

resource "aws_lb" "web_server_lb" {
  provider           = aws.region_1
  name               = "web-server-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_server_sg.id]

  subnets = [
    aws_subnet.subnet_region_1a.id,
    aws_subnet.subnet_region_1b.id
  ]

  enable_deletion_protection = false

  tags = {
    Name = "web_server_lb"
  }
}

resource "aws_lb_target_group" "web_server_tg" {
  provider = aws.region_1
  name     = "web-server-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_region_1.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "web_server_tg"
  }
}

resource "aws_lb_listener" "web_server_listener" {
  provider          = aws.region_1
  load_balancer_arn = aws_lb.web_server_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_server_tg.arn
  }
}

resource "aws_autoscaling_group" "web_server_asg" {
  provider = aws.region_1
  launch_template {
    id      = aws_launch_template.web_server_lt.id
    version = "$Latest"
  }
  
  min_size         = 2
  max_size         = 5
  desired_capacity = 2
  
  vpc_zone_identifier = [
    aws_subnet.subnet_region_1a.id,
    aws_subnet.subnet_region_1b.id
  ]

  target_group_arns = [aws_lb_target_group.web_server_tg.arn]

  tag {
    key                 = "Name"
    value               = "ASG_1"
    propagate_at_launch = true
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300
}
