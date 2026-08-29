# GuardDuty Detector
resource "aws_guardduty_detector" "main" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = local.tags
}

# GuardDuty EBS Malware Protection
resource "aws_guardduty_detector_feature" "ebs_malware_protection" {
  detector_id = aws_guardduty_detector.main.id
  name        = "EBS_MALWARE_PROTECTION"
  status      = "ENABLED"
}

# GuardDuty Threat Intel Set (example)
resource "aws_guardduty_threatintelset" "example" {
  activate    = true
  detector_id = aws_guardduty_detector.main.id
  format      = "TXT"
  location    = "https://s3.amazonaws.com/guardduty-threat-intel-set/example-threat-intel-set.txt"
  name        = "${local.project_name}-threat-intel-set"

  tags = local.tags
}

# GuardDuty IP Set (example - block known bad IPs)
resource "aws_guardduty_ipset" "example" {
  activate    = true
  detector_id = aws_guardduty_detector.main.id
  format      = "TXT"
  location    = "https://s3.amazonaws.com/guardduty-ip-set/example-ip-set.txt"
  name        = "${local.project_name}-ip-set"

  tags = local.tags
}
