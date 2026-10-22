resource "aws_rds_cluster" "personal" {
  cluster_identifier_prefix   = "webpage-personal-"
  engine                      = "aurora-mysql"
  engine_mode                 = "provisioned"
  engine_version              = var.aurora_engine_version
  database_name               = "personal_data"
  master_username             = "app_admin"
  manage_master_user_password = true
  enable_http_endpoint        = true
  storage_encrypted           = true
  db_subnet_group_name        = aws_db_subnet_group.personal.name
  vpc_security_group_ids      = [aws_security_group.database.id]
  backup_retention_period     = 7
  deletion_protection         = false
  skip_final_snapshot         = true
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 2
  }
}
