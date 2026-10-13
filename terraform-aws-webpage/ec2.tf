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

  iam_instance_profile {
    name = aws_iam_instance_profile.web.name
  }

  # Keep your existing network_interfaces, user_data,
  # metadata_options, and other settings here.

  depends_on = [aws_cloudwatch_log_group.web]

  network_interfaces {
    associate_public_ip_address = true
    delete_on_termination       = true
    security_groups             = [aws_security_group.ec2.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -euo pipefail

    dnf install -y httpd nodejs22 nodejs22-npm amazon-cloudwatch-agent

    # Configure CloudWatch first so startup errors are collected.
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'JSON'
    {
      "agent": {
        "metrics_collection_interval": 60
      },
      "metrics": {
        "namespace": "CWAgent",
        "append_dimensions": {
          "InstanceId": "$${aws:InstanceId}"
        },
        "metrics_collected": {
          "mem": {
            "measurement": ["mem_used_percent"]
          },
          "disk": {
            "measurement": ["used_percent"],
            "resources": ["/"]
          }
        }
      },
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/httpd/access_log",
                "log_group_name": "/terraform-webpage/apache-access",
                "log_stream_name": "{instance_id}"
              },
              {
                "file_path": "/var/log/httpd/error_log",
                "log_group_name": "/terraform-webpage/apache-error",
                "log_stream_name": "{instance_id}"
              },
              {
                "file_path": "/var/log/cloud-init-output.log",
                "log_group_name": "/terraform-webpage/startup",
                "log_stream_name": "{instance_id}"
              }
            ]
          }
        }
      }
    }
    JSON

    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config \
      -m ec2 \
      -s \
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

    systemctl enable amazon-cloudwatch-agent

    # Fetch the instance ID using IMDSv2.
    TOKEN=$(curl -fsS --retry 5 -X PUT \
      -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
      http://169.254.169.254/latest/api/token)

    INSTANCE_ID=$(curl -fsS --retry 5 \
      -H "X-aws-ec2-metadata-token: $TOKEN" \
      http://169.254.169.254/latest/meta-data/instance-id)

    # Build the React application as an unprivileged user.
    install -d -o ec2-user -g ec2-user /opt/react-app
    cd /opt/react-app

    cat > package.json <<'JSON'
    {
      "name": "terraform-webpage",
      "version": "1.0.0",
      "private": true,
      "type": "module",
      "scripts": {
        "build": "esbuild src.jsx --bundle --minify --outfile=dist/app.js"
      },
      "dependencies": {
        "react": "19.0.0",
        "react-dom": "19.0.0"
      },
      "devDependencies": {
        "esbuild": "0.25.0"
      }
    }
    JSON

    cat > src.jsx <<'JS'
    import React from "react";
    import { createRoot } from "react-dom/client";

    async function start() {
      const response = await fetch("/instance.json", {
        cache: "no-store"
      });
      if (!response.ok) throw new Error("Cannot load instance information");

      const instance = await response.json();

      createRoot(document.getElementById("root")).render(
        <main style={{
          fontFamily: "Arial, sans-serif",
          maxWidth: 700,
          margin: "80px auto",
          padding: 24
        }}>
          <h1>Hello from React on EC2!</h1>
          <p>This page came from instance:</p>
          <strong>{instance.instanceId}</strong>
          <p>Deployed using Terraform, Auto Scaling, and ALB.</p>
        </main>
      );
    }

    start().catch(error => {
      document.getElementById("root").textContent = error.message;
    });
    JS

    mkdir -p dist

    cat > dist/index.html <<'HTML'
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>React on AWS</title>
      </head>
      <body>
        <div id="root">Loading...</div>
        <script src="/app.js"></script>
      </body>
    </html>
    HTML

    printf '{"instanceId":"%s"}\n' "$INSTANCE_ID" > dist/instance.json

    chown -R ec2-user:ec2-user /opt/react-app

    runuser -u ec2-user -- bash -c \
      'cd /opt/react-app && npm-22 install --no-audit --no-fund && npm-22 run build'

    cp -r dist/. /var/www/html/
    restorecon -R /var/www/html

    # Prevent cached instance information when ALB selects another server.
    cat > /etc/httpd/conf.d/instance-info.conf <<'APACHE'
    <Location "/instance.json">
      Header always set Cache-Control "no-store"
    </Location>
    APACHE

    httpd -t
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