#alb
output "alb_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "api_url" {
  description = "Full URL to access the API"
  value       = "http://${aws_lb.this.dns_name}/api"
}

output "health_check_url" {
  description = "Health check endpoint URL"
  value       = "http://${aws_lb.this.dns_name}/health"
}

# ECS
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.api.name
}

output "ecs_task_definition" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.api.arn
}

# Cloudwatch
output "cloudwatch_dashboard_url" {
  description = "URL to access CloudWatch Dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for ECS logs"
  value       = aws_cloudwatch_log_group.ecs_logs.name
}

output "sns_topic_arn" {
  description = "SNS Topic ARN for alarms"
  value       = aws_sns_topic.alarms.arn
}

# Net
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnets" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

# Scaling
output "autoscaling_min_capacity" {
  description = "Minimum number of tasks"
  value       = aws_appautoscaling_target.ecs_target.min_capacity
}

output "autoscaling_max_capacity" {
  description = "Maximum number of tasks"
  value       = aws_appautoscaling_target.ecs_target.max_capacity
}

# CloudFront
output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.api.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.api.id
}

output "cloudfront_api_url" {
  description = "Production API URL via CloudFront (HTTPS)"
  value       = "https://${aws_cloudfront_distribution.api.domain_name}/api"
}

output "cloudfront_health_url" {
  description = "Health check URL via CloudFront"
  value       = "https://${aws_cloudfront_distribution.api.domain_name}/health"
}

output "cloudfront_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.api.arn
}