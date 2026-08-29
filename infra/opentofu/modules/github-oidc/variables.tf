variable "name_prefix" {
  description = "Prefix applied to GitHub OIDC roles and policies."
  type        = string
}

variable "aws_account_id" {
  description = "Expected staging AWS account ID."
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS Region hosting the staging runtime."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to assume staging roles."
  type        = string
}

variable "github_environment" {
  description = "GitHub Environment encoded in the OIDC subject claim."
  type        = string
}

variable "state_bucket_name" {
  description = "Existing S3 bucket used by the OpenTofu backend."
  type        = string
  sensitive   = true
}

variable "ecr_repository_arns" {
  description = "Application repositories writable by the deployment role."
  type        = set(string)
}

variable "docs_bucket_arn" {
  description = "Documentation bucket writable by the deployment role."
  type        = string
}

variable "deployment_bucket_arn" {
  description = "Deployment artifact bucket writable by the deployment role."
  type        = string
}

variable "cloudfront_distribution_arns" {
  description = "CloudFront distributions that the deployment role may invalidate."
  type        = set(string)
}

variable "instance_arn" {
  description = "Staging EC2 instance targeted by SSM deployments."
  type        = string
}

variable "tags" {
  description = "Tags applied to all supported resources."
  type        = map(string)
  default     = {}
}
