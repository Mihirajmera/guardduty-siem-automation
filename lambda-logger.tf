# Lambda function for logging all GuardDuty findings
resource "aws_lambda_function" "finding_logger" {
  filename         = "finding_logger.zip"
  function_name    = "${local.project_name}-finding-logger"
  role            = aws_iam_role.lambda_security_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 60

  environment {
    variables = {
      LOG_GROUP_NAME = aws_cloudwatch_log_group.guardduty_findings.name
    }
  }

  tags = local.tags
}

# Create the Lambda deployment package
data "archive_file" "finding_logger_zip" {
  type        = "zip"
  output_path = "finding_logger.zip"
  source {
    content = <<EOF
import json
import boto3
import logging
import os
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """
    Log all GuardDuty findings to CloudWatch
    """
    try:
        finding = event['detail']
        
        # Structure the log entry
        log_entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'finding_id': finding.get('id', 'unknown'),
            'finding_type': finding.get('type', 'unknown'),
            'severity': finding.get('severity', 0),
            'title': finding.get('title', ''),
            'description': finding.get('description', ''),
            'region': finding.get('region', ''),
            'account_id': finding.get('accountId', ''),
            'resource': finding.get('resource', {}),
            'service': finding.get('service', {}),
            'threat_intel_details': finding.get('threatIntelDetails', {}),
            'raw_event': event
        }
        
        # Log to CloudWatch
        logger.info(json.dumps(log_entry))
        
        return {
            'statusCode': 200,
            'body': json.dumps('Finding logged successfully')
        }
        
    except Exception as e:
        logger.error(f"Error logging finding: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }
EOF
    filename = "index.py"
  }
}

# EventBridge target for finding logger
resource "aws_cloudwatch_event_target" "logger_target" {
  rule      = aws_cloudwatch_event_rule.guardduty_all_findings.name
  target_id = "FindingLoggerTarget"
  arn       = aws_lambda_function.finding_logger.arn
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "allow_logger_eventbridge" {
  statement_id  = "AllowLoggerExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.finding_logger.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_all_findings.arn
}
