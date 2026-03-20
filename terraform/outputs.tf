output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (web tier)"
  value       = module.networking.public_subnet_ids
}

output "app_subnet_ids" {
  description = "Private subnet IDs (app tier)"
  value       = module.networking.app_subnet_ids
}

output "db_subnet_ids" {
  description = "Private subnet IDs (database tier)"
  value       = module.networking.db_subnet_ids
}

output "web_alb_dns_name" {
  description = "DNS name of the public-facing Application Load Balancer"
  value       = module.web.alb_dns_name
}

output "web_alb_zone_id" {
  description = "Hosted zone ID of the public-facing ALB (for Route 53 alias records)"
  value       = module.web.alb_zone_id
}

output "app_alb_dns_name" {
  description = "DNS name of the internal Application Load Balancer"
  value       = module.app.alb_dns_name
}

output "db_endpoint" {
  description = "RDS database endpoint"
  value       = module.database.db_endpoint
  sensitive   = true
}

output "db_secret_arn" {
  description = "ARN of Secrets Manager secret holding the DB password"
  value       = module.database.db_secret_arn
}

output "web_asg_name" {
  description = "Name of the web tier Auto Scaling Group"
  value       = module.web.asg_name
}

output "app_asg_name" {
  description = "Name of the app tier Auto Scaling Group"
  value       = module.app.asg_name
}
