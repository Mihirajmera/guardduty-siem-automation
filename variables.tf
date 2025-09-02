variable "project_name" {
  description = "Project name used for tagging and resource naming."
  type        = string
  default     = "guardduty-siem"
}

variable "aws_region" {
  description = "AWS region to deploy resources."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "notification_email" {
  description = "Email address for security alerts."
  type        = string
  default     = "security@example.com"
}

variable "quarantine_severity_threshold" {
  description = "Minimum severity level to trigger auto-quarantine (LOW, MEDIUM, HIGH, CRITICAL)."
  type        = string
  default     = "HIGH"
}

variable "tags" {
  description = "Additional tags to apply to resources."
  type        = map(string)
  default     = {}
}
