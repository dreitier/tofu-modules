# Credentials from the AWS shared config profile (IAM Identity Center via Entra, or a break-glass
# profile) – nothing secret passes through OpenTofu
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# The Route53 Domains API exists in us-east-1 only
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = var.aws_profile
}
