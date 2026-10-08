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

resource "aws_instance" "web" {
  count = 2

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  subnet_id = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ][count.index]

  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.web.key_name

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    set -eux

    dnf install -y httpd

    cat > /var/www/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html>
      <head>
        <title>Terraform AWS Webpage</title>
      </head>
      <body>
        <h1>Hello from EC2 instance ${count.index + 1}!</h1>
        <p>Deployed using Terraform, EC2, ALB, and VPC.</p>
      </body>
    </html>
    HTML

    systemctl enable --now httpd
  EOF

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  depends_on = [
    aws_route_table_association.public_1,
    aws_route_table_association.public_2
  ]

  tags = {
    Name = "webpage-ec2-${count.index + 1}"
  }
}