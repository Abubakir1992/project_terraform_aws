resource "aws_subnet" "database" {
  for_each = {
    a = { cidr = "10.0.11.0/24", az = "us-east-1a" }
    b = { cidr = "10.0.12.0/24", az = "us-east-1b" }
  }
  vpc_id            = aws_vpc.web_vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags              = { Name = "web-database-${each.key}" }
}
