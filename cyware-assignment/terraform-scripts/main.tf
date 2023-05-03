# AWS provider configuration
provider "aws" {
  region = "ap-south-1"
}

# VPC configuration
resource "aws_vpc" "sample" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "sample"
  }
}

# Public subnet configuration
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.sample.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "ap-south-1a"

  tags = {
    Name = "public"
  }
}

# Private subnet configuration
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.sample.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "private"
  }
}

# Internet Gateway Configuration
resource "aws_internet_gateway" "testgateway" {
  vpc_id = aws_vpc.sample.id

  tags = {
    Name = "testgateway"
  }
}

# Route Table Configuration
resource "aws_route_table" "testroutetable" {
  vpc_id = aws_vpc.sample.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.testgateway.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.testgateway.id
  }

  tags = {
    Name = "testroutetable"
  }
}

# Route Table Association
resource "aws_route_table_association" "test" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.testroutetable.id
}

# Security Group Configuration
resource "aws_security_group" "ec2-sg" {
  vpc_id      = aws_vpc.sample.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

resource "aws_security_group" "alb-sg" {
  name_prefix = "alb_sg"
  vpc_id      = aws_vpc.sample.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

# EC2 Configuration
resource "aws_instance" "testec2" {
  ami           = "ami-02eb7a4783e7e9317"
  instance_type = "t2.micro"
  key_name      = "MyKeyPair"

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2-sg.id]
  associate_public_ip_address = true
 
  tags = {
    "Name" : "testec2"
  }
}

# Load Balancer Target Group Configuration

resource "aws_lb_target_group" "lb-tg" {
  name     = "lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.sample.id
  
  health_check {
    path = "/"
    port = 80
    protocol = "HTTP"
    timeout = 5
    interval = 10
    unhealthy_threshold = 2
    healthy_threshold = 2
  }

}


# Load Balancer Configuration

resource "aws_lb" "test_lb" {
  name = "test_lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb-sg.id]
  subnets = [aws_subnet.public.id]

  listener {
    protocol = "HTTP"
    port = 80
  }
  
  default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.lb-tg.arn
  }
}
