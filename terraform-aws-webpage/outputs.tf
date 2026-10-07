output "vpc_id" {
  value = aws_vpc.web_vpc.id
}

output "ec2_id" {
  value = aws_instance.web.id
}

output "ec2_private_ip" {
  value = aws_instance.web.private_ip
}

output "alb_dns_name" {
  value = aws_lb.web.dns_name
}

output "website" {
  value = "http://${aws_lb.web.dns_name}"
}