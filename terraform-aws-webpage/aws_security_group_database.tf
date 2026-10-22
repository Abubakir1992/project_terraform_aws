resource "aws_security_group" "database" {
  name_prefix = "webpage-database-"
  description = "No inbound SQL connections; use authenticated RDS Data API"
  vpc_id      = aws_vpc.web_vpc.id
}
