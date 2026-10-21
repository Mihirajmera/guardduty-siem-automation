# IaC compliance evidence: guardduty-siem-automation

Checkov 3.3.22 scanned the Terraform on 2026-10-21. Scan output SHA-256: `cf7b5bb5353a495c…`.

| Passed | Failed, open | Failed, exception | Unique checks |
|---:|---:|---:|---:|
| 60 | **0** | 23 | 57 |

**Gate:** CI fails if any failed check lacks a reviewed, unexpired exception.

## Exceptions

Reviewed 2026-10-21 by Mihir Ajmera. Each one is a decision with a reason and an expiry, not a suppression.

| Check | Resource | Decision | Reason | Expires | NIST 800-53 |
|---|---|---|---|---|---|
| CKV2_AWS_10 Ensure CloudTrail trails are integrated with CloudWatch Logs | `aws_cloudtrail.main` | risk-accepted | Detection runs through GuardDuty and EventBridge rather than CloudWatch metric filters on CloudTrail, so the CloudTrail-to-CloudWatch integration would duplicate it. | 2027-04-21 | AU-6, SI-4 |
| CKV2_AWS_3 Ensure GuardDuty is enabled to specific org/region | `aws_guardduty_detector.main` | not-applicable | Single-account deployment. Organization-wide GuardDuty with a delegated administrator applies in AWS Organizations setups. | 2027-04-21 | SI-4 |
| CKV2_AWS_61 Ensure that an S3 bucket has a lifecycle configuration | `aws_s3_bucket.cloudtrail` | deferred | Add a lifecycle rule (archive after 90 days, keep for the agreed retention period). | 2027-01-31 | SI-12 |
| CKV2_AWS_62 Ensure S3 buckets should have event notifications enabled | `aws_s3_bucket.cloudtrail` | not-applicable | No consumer needs object-level events for the trail bucket. | 2027-04-21 | SI-4 |
| CKV_AWS_115 Ensure that AWS Lambda function is configured for function-level concurrent execution limit | `aws_lambda_function.auto_quarantine` | not-applicable | Triggered by GuardDuty findings at low volume; account concurrency limits are sufficient. | 2027-04-21 | SC-5 |
| CKV_AWS_115 Ensure that AWS Lambda function is configured for function-level concurrent execution limit | `aws_lambda_function.finding_logger` | not-applicable | Triggered by GuardDuty findings at low volume; account concurrency limits are sufficient. | 2027-04-21 | SC-5 |
| CKV_AWS_116 Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ) | `aws_lambda_function.auto_quarantine` | deferred | Add a dead-letter queue so a failed quarantine is retained and alerted on. | 2027-01-31 | SI-11 |
| CKV_AWS_116 Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ) | `aws_lambda_function.finding_logger` | deferred | Add a dead-letter queue so a failed quarantine is retained and alerted on. | 2027-01-31 | SI-11 |
| CKV_AWS_117 Ensure that AWS Lambda function is configured inside a VPC | `aws_lambda_function.auto_quarantine` | not-applicable | Functions only call public AWS APIs (EC2, SNS); placing them in a VPC would add NAT cost without reducing exposure. | 2027-04-21 | SC-7 |
| CKV_AWS_117 Ensure that AWS Lambda function is configured inside a VPC | `aws_lambda_function.finding_logger` | not-applicable | Functions only call public AWS APIs (EC2, SNS); placing them in a VPC would add NAT cost without reducing exposure. | 2027-04-21 | SC-7 |
| CKV_AWS_144 Ensure that S3 bucket has cross-region replication enabled | `aws_s3_bucket.cloudtrail` | not-applicable | Single-region reference deployment; cross-region replication of trail logs belongs to a production disaster-recovery design. | 2027-04-21 | CP-9, CP-6 |
| CKV_AWS_145 Ensure that S3 buckets are encrypted with KMS by default | `aws_s3_bucket.cloudtrail` | deferred | Same customer-managed KMS key work as CKV_AWS_35. | 2027-01-31 | SC-28, SC-12 |
| CKV_AWS_158 Ensure that CloudWatch Log Group is encrypted by KMS | `aws_cloudwatch_log_group.guardduty_findings` | risk-accepted | Encrypted with the CloudWatch Logs service key. A customer-managed key adds key-policy management with little benefit here. | 2027-04-21 | SC-28 |
| CKV_AWS_173 Check encryption settings for Lambda environmental variable | `aws_lambda_function.auto_quarantine` | not-applicable | Environment variables hold only resource identifiers, no secrets; default Lambda encryption at rest applies. | 2027-04-21 | SC-28 |
| CKV_AWS_173 Check encryption settings for Lambda environmental variable | `aws_lambda_function.finding_logger` | not-applicable | Environment variables hold only resource identifiers, no secrets; default Lambda encryption at rest applies. | 2027-04-21 | SC-28 |
| CKV_AWS_18 Ensure the S3 bucket has access logging enabled | `aws_s3_bucket.cloudtrail` | deferred | Server access logging for the CloudTrail bucket needs a separate log bucket. | 2027-01-31 | AU-2, AU-12 |
| CKV_AWS_252 Ensure CloudTrail defines an SNS Topic | `aws_cloudtrail.main` | not-applicable | Log-delivery notifications aren't consumed; security alerts go to the security_alerts SNS topic from the EventBridge pipeline. | 2027-04-21 | AU-5, SI-4 |
| CKV_AWS_26 Ensure all data stored in the SNS topic is encrypted | `aws_sns_topic.security_alerts` | deferred | Enable SSE with the AWS-managed SNS key; alert messages contain finding metadata. | 2027-01-31 | SC-28 |
| CKV_AWS_272 Ensure AWS Lambda function is configured to validate code-signing | `aws_lambda_function.auto_quarantine` | deferred | Code signing needs an AWS Signer profile; planned with the move to packaged deployment artifacts. | 2027-01-31 | SI-7, CM-14 |
| CKV_AWS_272 Ensure AWS Lambda function is configured to validate code-signing | `aws_lambda_function.finding_logger` | deferred | Code signing needs an AWS Signer profile; planned with the move to packaged deployment artifacts. | 2027-01-31 | SI-7, CM-14 |
| CKV_AWS_35 Ensure CloudTrail logs are encrypted at rest using KMS CMKs | `aws_cloudtrail.main` | deferred | Encrypt CloudTrail logs with a customer-managed KMS key (CIS AWS 3.5); needs a key policy for the CloudTrail service. Logs are encrypted with SSE-S3 and integrity-protected by log file validation meanwhile. | 2027-01-31 | AU-9, SC-28 |
| CKV_AWS_50 X-Ray tracing is enabled for Lambda | `aws_lambda_function.auto_quarantine` | not-applicable | Small event-driven functions; CloudWatch Logs are enough and X-Ray adds cost without diagnostic value here. | 2027-04-21 | AU-12, SI-4 |
| CKV_AWS_50 X-Ray tracing is enabled for Lambda | `aws_lambda_function.finding_logger` | not-applicable | Small event-driven functions; CloudWatch Logs are enough and X-Ray adds cost without diagnostic value here. | 2027-04-21 | AU-12, SI-4 |

## Passed checks by NIST 800-53 control

| Control | Passed checks |
|---|---:|
| AC-2 | 2 |
| AC-21 | 2 |
| AC-3 | 20 |
| AC-4 | 2 |
| AC-6 | 33 |
| AU-11 | 2 |
| AU-12 | 2 |
| AU-2 | 2 |
| AU-9 | 1 |
| CP-9 | 1 |
| IA-5 | 5 |
| IA-8 | 3 |
| SA-22 | 2 |
| SC-28 | 1 |
| SC-7 | 9 |
| SI-12 | 1 |
| SI-2 | 2 |
| SI-4 | 1 |

Mappings to NIST 800-53 and CIS are my own judgment ([`iac_controls.yaml`](iac_controls.yaml)); checks without a mapping are counted as *unmapped*.
