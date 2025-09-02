# Lambda function for auto-quarantine
resource "aws_lambda_function" "auto_quarantine" {
  filename         = "auto_quarantine.zip"
  function_name    = "${local.project_name}-auto-quarantine"
  role            = aws_iam_role.lambda_security_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.security_alerts.arn
      SEVERITY_THRESHOLD = var.quarantine_severity_threshold
    }
  }

  tags = local.tags
}

# Create the Lambda deployment package
data "archive_file" "auto_quarantine_zip" {
  type        = "zip"
  output_path = "auto_quarantine.zip"
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
    Auto-quarantine EC2 instances based on GuardDuty findings
    """
    try:
        sns_client = boto3.client('sns')
        ec2_client = boto3.client('ec2')
        
        finding = event['detail']
        severity = finding.get('severity', 0)
        finding_type = finding.get('type', '')
        service = finding.get('service', {})
        resource = finding.get('resource', {})
        
        # Check if severity meets threshold
        severity_threshold = os.environ.get('SEVERITY_THRESHOLD', 'HIGH')
        severity_map = {'LOW': 1, 'MEDIUM': 4, 'HIGH': 7, 'CRITICAL': 9}
        
        if severity < severity_map.get(severity_threshold, 7):
            logger.info(f"Finding severity {severity} below threshold {severity_threshold}")
            return {
                'statusCode': 200,
                'body': json.dumps('Severity below threshold, no quarantine needed')
            }
        
        # Extract instance information
        instance_id = None
        if 'instanceDetails' in resource:
            instance_id = resource['instanceDetails'].get('instanceId')
        elif 'instanceId' in resource:
            instance_id = resource['instanceId']
        
        if not instance_id:
            logger.warning("No instance ID found in finding")
            return {
                'statusCode': 400,
                'body': json.dumps('No instance ID found')
            }
        
        # Get instance details
        try:
            response = ec2_client.describe_instances(InstanceIds=[instance_id])
            if not response['Reservations']:
                logger.error(f"Instance {instance_id} not found")
                return {
                    'statusCode': 404,
                    'body': json.dumps(f'Instance {instance_id} not found')
                }
            
            instance = response['Reservations'][0]['Instances'][0]
            state = instance['State']['Name']
            
            if state in ['stopped', 'terminated']:
                logger.info(f"Instance {instance_id} already {state}")
                return {
                    'statusCode': 200,
                    'body': json.dumps(f'Instance already {state}')
                }
            
        except Exception as e:
            logger.error(f"Error describing instance {instance_id}: {str(e)}")
            return {
                'statusCode': 500,
                'body': json.dumps(f'Error describing instance: {str(e)}')
            }
        
        # Quarantine actions
        quarantine_actions = []
        
        # 1. Stop the instance
        try:
            ec2_client.stop_instances(InstanceIds=[instance_id])
            quarantine_actions.append(f"Stopped instance {instance_id}")
            logger.info(f"Stopped instance {instance_id}")
        except Exception as e:
            logger.error(f"Error stopping instance {instance_id}: {str(e)}")
            quarantine_actions.append(f"Failed to stop instance {instance_id}: {str(e)}")
        
        # 2. Remove all security group rules (create quarantine SG)
        try:
            # Create quarantine security group
            quarantine_sg = ec2_client.create_security_group(
                GroupName=f"quarantine-{instance_id}",
                Description=f"Quarantine security group for {instance_id}",
                VpcId=instance['VpcId']
            )
            
            quarantine_sg_id = quarantine_sg['GroupId']
            
            # Modify instance to use only quarantine security group
            ec2_client.modify_instance_attribute(
                InstanceId=instance_id,
                Groups=[quarantine_sg_id]
            )
            
            quarantine_actions.append(f"Applied quarantine security group {quarantine_sg_id}")
            logger.info(f"Applied quarantine security group {quarantine_sg_id}")
            
        except Exception as e:
            logger.error(f"Error applying quarantine security group: {str(e)}")
            quarantine_actions.append(f"Failed to apply quarantine security group: {str(e)}")
        
        # 3. Add quarantine tag
        try:
            ec2_client.create_tags(
                Resources=[instance_id],
                Tags=[
                    {
                        'Key': 'Quarantine',
                        'Value': 'true'
                    },
                    {
                        'Key': 'QuarantineReason',
                        'Value': finding_type
                    },
                    {
                        'Key': 'QuarantineDate',
                        'Value': datetime.utcnow().isoformat()
                    },
                    {
                        'Key': 'GuardDutyFindingId',
                        'Value': finding.get('id', 'unknown')
                    }
                ]
            )
            quarantine_actions.append("Added quarantine tags")
            logger.info("Added quarantine tags")
            
        except Exception as e:
            logger.error(f"Error adding quarantine tags: {str(e)}")
            quarantine_actions.append(f"Failed to add quarantine tags: {str(e)}")
        
        # Send notification
        message = f"""
        🚨 SECURITY ALERT - AUTO-QUARANTINE TRIGGERED 🚨
        
        Instance: {instance_id}
        Finding Type: {finding_type}
        Severity: {severity}
        Finding ID: {finding.get('id', 'unknown')}
        
        Quarantine Actions Taken:
        {chr(10).join(f"• {action}" for action in quarantine_actions)}
        
        Time: {datetime.utcnow().isoformat()}
        
        Please investigate immediately and determine if the instance should be terminated.
        """
        
        sns_client.publish(
            TopicArn=os.environ['SNS_TOPIC_ARN'],
            Subject=f"🚨 AUTO-QUARANTINE: {instance_id} - {finding_type}",
            Message=message
        )
        
        logger.info(f"Sent quarantine notification for instance {instance_id}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': f'Successfully quarantined instance {instance_id}',
                'actions': quarantine_actions
            })
        }
        
    except Exception as e:
        logger.error(f"Error in auto-quarantine function: {str(e)}")
        
        # Send error notification
        try:
            sns_client.publish(
                TopicArn=os.environ['SNS_TOPIC_ARN'],
                Subject="🚨 AUTO-QUARANTINE ERROR",
                Message=f"Error in auto-quarantine function: {str(e)}"
            )
        except:
            pass
        
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }
EOF
    filename = "index.py"
  }
}

# EventBridge target for auto-quarantine
resource "aws_cloudwatch_event_target" "quarantine_target" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "AutoQuarantineTarget"
  arn       = aws_lambda_function.auto_quarantine.arn
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "allow_quarantine_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_quarantine.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_findings.arn
}
