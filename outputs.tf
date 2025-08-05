
output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.main.id
}

output "ssm_host_public_ip" {
  description = "Public IP of the SSM EC2 instance"
  value       = aws_instance.ssm_host.public_ip
}

output "rds_master_endpoint" {
  description = "RDS MariaDB master endpoint"
  value       = aws_db_instance.mariadb_master.endpoint
}

output "rds_replica_endpoint" {
  description = "RDS MariaDB replica endpoint"
  value       = aws_db_instance.mariadb_replica.endpoint
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = aws_lb.nlb.dns_name
}

output "cloudfront_domain" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "s3_bucket_name" {
  description = "S3 bucket used as CloudFront origin"
  value       = aws_s3_bucket.web_assets.bucket
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.ec2_asg.name
}
