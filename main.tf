provider "aws" {
  region = "ap-south-1"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_instance" "webserver" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  subnet_id = data.aws_subnets.default.ids[0]

  monitoring = true

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y stress-ng
    stress-ng --cpu 2 --timeout 15m
  EOF

  tags = {
    Name    = "Project3-EC2"
    Project = "EC2-State-Monitoring"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name        = "P3-EC2-CPU-CRITICAL"
  alarm_description = "Project 3 EC2 CPU utilization critical alert"

  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1

  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"

  period    = 60
  statistic = "Average"
  threshold = 70

  dimensions = {
    InstanceId = aws_instance.webserver.id
  }

  treat_missing_data = "notBreaching"
}
