resource "aws_route_table" "database" {
  vpc_id = aws_vpc.web_vpc.id
}
