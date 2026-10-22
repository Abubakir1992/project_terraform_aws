resource "aws_db_subnet_group" "personal" {
  name_prefix = "webpage-personal-"
  subnet_ids  = [for subnet in aws_subnet.database : subnet.id]
}
