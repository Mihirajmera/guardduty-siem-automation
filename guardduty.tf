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

# GuardDuty Finding Publishing Frequency
resource "aws_guardduty_detector_feature" "malware_protection" {
  detector_id = aws_guardduty_detector.main.id
  name        = "MALWARE_PROTECTION"
  status      = "ENABLED"
}

resource "aws_guardduty_detector_feature" "malware_protection_scan_ec2" {
  detector_id = aws_guardduty_detector.main.id
  name        = "MALWARE_PROTECTION_SCAN_EC2_INSTANCE_WITH_FINDINGS"
  status      = "ENABLED"
  additional_configuration {
    name   = "EBS_MALWARE_PROTECTION"
    status = "ENABLED"
  }
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
