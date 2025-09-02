output "guardduty_detector_id" {
  value       = aws_guardduty_detector.main.id
  description = "GuardDuty detector ID"
}

output "cloudtrail_arn" {
  value       = aws_cloudtrail.main.arn
  description = "CloudTrail ARN"
}

output "sns_topic_arn" {
  value       = aws_sns_topic.security_alerts.arn
  description = "SNS topic ARN for security alerts"
}

output "cloudwatch_log_group_name" {
  value       = aws_cloudwatch_log_group.guardduty_findings.name
  description = "CloudWatch log group name for GuardDuty findings"
}

output "auto_quarantine_function_name" {
  value       = aws_lambda_function.auto_quarantine.function_name
  description = "Auto-quarantine Lambda function name"
}

output "finding_logger_function_name" {
  value       = aws_lambda_function.finding_logger.function_name
  description = "Finding logger Lambda function name"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.cloudtrail.bucket
  description = "S3 bucket name for CloudTrail logs"
}
