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

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "web" {
  name_prefix   = "webpage-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.web.key_name

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups             = [aws_security_group.ec2.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -eux

    dnf install -y httpd

    TOKEN=$(curl -fsS -X PUT \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
      http://169.254.169.254/latest/api/token)

    INSTANCE_ID=$(curl -fsS \
      -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/instance-id)

    cat > /var/www/html/index.html <<HTML
    <!DOCTYPE html>
    <html>
      <head>
        <title>Terraform AWS Webpage</title>
      </head>
      <body>
        <h1>Hello from EC2!</h1>
        <p>This page came from instance: <strong>$INSTANCE_ID</strong></p>
      </body>
    </html>
    HTML

    systemctl enable --now httpd
  EOF
  )

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 30
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "webpage-asg-instance"
    }
  }
}

resource "aws_autoscaling_group" "web" {
  name                      = "webpage-asg"
  min_size                  = 2
  desired_capacity          = 2
  max_size                  = 4
  health_check_type         = "ELB"
  health_check_grace_period = 300
  default_instance_warmup   = 300

  vpc_zone_identifier = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  target_group_arns = [aws_lb_target_group.web.arn]

  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 100
      instance_warmup        = 300
    }
  }

  tag {
    key                 = "Name"
    value               = "webpage-asg-instance"
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }

  depends_on = [
    aws_route_table_association.public_1,
    aws_route_table_association.public_2,
    aws_lb_listener.http
  ]
}

resource "aws_autoscaling_policy" "web_cpu" {
  name                   = "webpage-cpu-scaling"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50
  }
}