variable "aws_account_id" {
  description = "Staging member-account ID. Supply through TF_VAR_aws_account_id."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must contain exactly 12 digits."
  }
}

variable "aws_region" {
  description = "Primary AWS Region for staging."
  type        = string
  default     = "ap-southeast-2"
}

variable "state_bucket_name" {
  description = "Existing bootstrap bucket used by the S3 backend."
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for aliencommons.com."
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[0-9a-f]{32}$", var.cloudflare_zone_id))
    error_message = "cloudflare_zone_id must be a 32-character lowercase hexadecimal ID."
  }
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the staging OIDC roles."
  type        = string
  default     = "AlienCommons/aliencommons"

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must use the owner/repository form."
  }
}

variable "availability_zone" {
  description = "Optional fixed Availability Zone; defaults to the first available zone."
  type        = string
  default     = null
  nullable    = true
}

variable "vpc_cidr" {
  description = "IPv4 CIDR for the staging VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "IPv4 CIDR for the single public staging subnet."
  type        = string
  default     = "10.20.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for the initial staging host."
  type        = string
  default     = "t3.small"
}

variable "root_volume_size" {
  description = "Encrypted gp3 root volume size in GiB."
  type        = number
  default     = 50

  validation {
    condition     = var.root_volume_size >= 30
    error_message = "root_volume_size must be at least 30 GiB."
  }
}

variable "ami_ssm_parameter_name" {
  description = "Canonical public SSM parameter for the Ubuntu 24.04 amd64 AMI."
  type        = string
  default     = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

variable "origin_certificate_parameter_name" {
  description = "Existing SSM SecureString name containing the Origin CA certificate."
  type        = string
  default     = "/aliencommons/stg/traefik/origin-certificate"

  validation {
    condition     = startswith(var.origin_certificate_parameter_name, "/")
    error_message = "origin_certificate_parameter_name must be an absolute SSM parameter path."
  }
}

variable "origin_private_key_parameter_name" {
  description = "Existing SSM SecureString name containing the Origin CA private key."
  type        = string
  default     = "/aliencommons/stg/traefik/origin-private-key"

  validation {
    condition     = startswith(var.origin_private_key_parameter_name, "/")
    error_message = "origin_private_key_parameter_name must be an absolute SSM parameter path."
  }
}

variable "cloudfront_price_class" {
  description = "CloudFront edge-location price class used as the private S3 gateway."
  type        = string
  default     = "PriceClass_All"
}
