variable "name_prefix" {
  description = "Prefix applied to compute and runtime IAM resources."
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

variable "subnet_id" {
  description = "Public subnet for the staging instance."
  type        = string
}

variable "security_group_id" {
  description = "Security group restricted to Cloudflare HTTPS ingress."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for staging."
  type        = string
}

variable "root_volume_size" {
  description = "Encrypted gp3 root volume size in GiB."
  type        = number
}

variable "ami_ssm_parameter_name" {
  description = "Public SSM parameter containing the approved Ubuntu AMI ID."
  type        = string
}

variable "ecr_repository_arns" {
  description = "Application ECR repository ARNs readable by the instance."
  type        = set(string)
}

variable "media_bucket_arn" {
  description = "Media bucket used by Django."
  type        = string
}

variable "deployment_bucket_arn" {
  description = "Private bucket containing deployment bundles."
  type        = string
}

variable "origin_certificate_parameter_name" {
  description = "SSM SecureString name containing the Cloudflare Origin CA certificate."
  type        = string
}

variable "origin_private_key_parameter_name" {
  description = "SSM SecureString name containing the Cloudflare Origin CA private key."
  type        = string
}

variable "tags" {
  description = "Tags applied to all supported resources."
  type        = map(string)
  default     = {}
}
