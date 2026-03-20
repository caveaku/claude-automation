output "db_endpoint" {
  value     = aws_db_instance.main.address
  sensitive = true
}

output "db_port" {
  value = aws_db_instance.main.port
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}

output "db_instance_id" {
  value = aws_db_instance.main.id
}

output "db_kms_key_arn" {
  value = aws_kms_key.rds.arn
}
