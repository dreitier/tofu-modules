# Credentials from the AWS shared config profile (IAM Identity Center via Keycloak, or a break-glass
# profile) – nothing secret passes through OpenTofu
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
