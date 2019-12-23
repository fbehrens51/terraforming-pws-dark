output "rds_address" {
  value = aws_db_instance.rds.address
}

output "rds_port" {
  value = aws_db_instance.rds.port
}

output "rds_username" {
  value = aws_db_instance.rds.username
}

output "rds_password" {
  sensitive = true
  value     = aws_db_instance.rds.password
}

output "rds_db_name" {
  value = aws_db_instance.rds.name
}

