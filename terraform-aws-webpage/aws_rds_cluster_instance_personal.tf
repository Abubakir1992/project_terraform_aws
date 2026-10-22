resource "aws_rds_cluster_instance" "personal" {
  identifier_prefix   = "webpage-personal-"
  cluster_identifier  = aws_rds_cluster.personal.id
  instance_class      = "db.serverless"
  engine              = aws_rds_cluster.personal.engine
  engine_version      = aws_rds_cluster.personal.engine_version
  publicly_accessible = false
}
