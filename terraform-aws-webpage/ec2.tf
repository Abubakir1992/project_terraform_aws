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

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.public_1.id

  vpc_security_group_ids = [
    aws_security_group.ec2.id
  ]

  user_data = <<-EOF
    #!/bin/bash

    dnf update -y
    dnf install -y httpd

    systemctl enable httpd
    systemctl start httpd

    cat > /var/www/html/index.html <<'HTML'
    <!DOCTYPE html>
    <html>
    <head>
      <title>Terraform Web Server</title>
    </head>

    <body>
      <h1>Hello from Terraform!</h1>
      <p>AWS EC2 + ALB + VPC</p>
    </body>
    </html>
    HTML
  EOF

  tags = {
    Name = "web-server"
  }
}