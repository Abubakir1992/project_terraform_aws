output "vpc_id" {
  value = aws_vpc.web_vpc.id
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.web.name
}

output "launch_template_id" {
  value = aws_launch_template.web.id
}

output "alb_dns_name" {
  value = aws_lb.web.dns_name
}

output "website" {
  value = "http://${aws_lb.web.dns_name}"
}