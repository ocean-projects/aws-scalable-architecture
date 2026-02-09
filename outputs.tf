output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web_server_lb.dns_name
}

output "primary_db_endpoint" {
  description = "Endpoint of the primary MySQL RDS instance"
  value       = aws_db_instance.mysql_instance_2.endpoint
}

output "read_replica_endpoint" {
  description = "Endpoint of the MySQL read replica in region 1"
  value       = aws_db_instance.mysql_instance_2_read_replica.endpoint
}
