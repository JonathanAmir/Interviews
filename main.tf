provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "subnet-1"
  }
}

resource "aws_subnet" "subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "subnet-2"
  }
}

resource "aws_security_group" "allow_all" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_all"
  }
}

resource "aws_launch_configuration" "app" {
  name          = "app-launch-configuration"
  image_id      = "ami-0c55b159cbfafe1f0" # Update with your AMI ID
  instance_type = "t2.micro"

  security_groups = [aws_security_group.allow_all.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World!" > index.html
              nohup busybox httpd -f -p 80 &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  vpc_zone_identifier = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id]
  desired_capacity    = 2
  max_size            = 2
  min_size            = 1
  launch_configuration = aws_launch_configuration.app.id

  tag {
    key                 = "Name"
    value               = "app-instance"
    propagate_at_launch = true
  }
}

resource "aws_elb" "app" {
  name               = "app-lb"
  availability_zones = ["us-east-1a", "us-east-1b"]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "app-elb"
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.app.name
  elb                    = aws_elb.app.name
}
