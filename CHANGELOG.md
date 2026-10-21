# Changelog

## Unreleased

- **Compliance evidence in CI:** Checkov results mapped to NIST 800-53 and CIS AWS v3.0.0, a reviewed exceptions register, and a gate that fails on unexcepted findings. Report and OSCAL output in `compliance/`.
- **Fixed:** the quarantine Lambda calls `ec2:CreateSecurityGroup`, which its policy didn't grant, so isolating an instance would have failed; meanwhile the policy granted unused `ec2:TerminateInstances`, security-group revokes and GuardDuty actions on `*`. It now grants exactly the calls the code makes, scoped to instance, VPC and security-group ARNs.
- CloudTrail log file validation enabled (CIS AWS 3.2); Lambda runtime python3.9 (deprecated) -> python3.12; GuardDuty findings log kept for one year.
## 1.0.0 (2026-10-17)

First tagged release. GuardDuty, CloudTrail and EventBridge pipeline with Lambda logging and auto-quarantine, plus a React findings dashboard.

- CI on Python 3.11 / current Terraform tooling with every GitHub Action pinned to a commit SHA
- CodeQL, OpenSSF Scorecard and Dependabot
- Security policy with private vulnerability reporting
