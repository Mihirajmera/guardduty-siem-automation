# EventBridge Rule for GuardDuty Findings
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "${local.project_name}-guardduty-findings"
  description = "Capture GuardDuty security findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [
        { numeric = [">=", 7.0] }  # HIGH and CRITICAL findings
      ]
    }
  })

  tags = local.tags
}

# EventBridge Rule for all GuardDuty findings (for logging)
resource "aws_cloudwatch_event_rule" "guardduty_all_findings" {
  name        = "${local.project_name}-guardduty-all-findings"
  description = "Capture all GuardDuty findings for logging"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
  })

  tags = local.tags
}

# SNS Topic for Security Alerts
resource "aws_sns_topic" "security_alerts" {
  name = "${local.project_name}-security-alerts"

  tags = local.tags
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# CloudWatch Log Group for GuardDuty findings
resource "aws_cloudwatch_log_group" "guardduty_findings" {
  name              = "/aws/guardduty/${local.project_name}/findings"
  retention_in_days = 30

  tags = local.tags
}

# IAM Role for Lambda functions
resource "aws_iam_role" "lambda_security_role" {
  name = "${local.project_name}-lambda-security-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_security_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM Policy for Lambda security functions
data "aws_iam_policy_document" "lambda_security_policy" {
  statement {
    sid    = "EC2QuarantineActions"
    effect = "Allow"
    actions = [
      "ec2:StopInstances",
      "ec2:TerminateInstances",
      "ec2:ModifyInstanceAttribute",
      "ec2:CreateTags",
      "ec2:DescribeInstances",
      "ec2:DescribeSecurityGroups",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "SNSNotifications"
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [aws_sns_topic.security_alerts.arn]
  }

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "GuardDutyAccess"
    effect = "Allow"
    actions = [
      "guardduty:GetFindings",
      "guardduty:ListFindings",
      "guardduty:UpdateFindingsFeedback"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_security_policy" {
  name        = "${local.project_name}-lambda-security-policy"
  description = "Policy for Lambda security functions"
  policy      = data.aws_iam_policy_document.lambda_security_policy.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "lambda_security_policy" {
  role       = aws_iam_role.lambda_security_role.name
  policy_arn = aws_iam_policy.lambda_security_policy.arn
}
