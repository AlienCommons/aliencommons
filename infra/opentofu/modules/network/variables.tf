variable "name_prefix" {
  description = "Prefix applied to staging network resources."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR for the staging VPC."
  type        = string
}

variable "public_subnet_cidr" {
  description = "IPv4 CIDR for the public staging subnet."
  type        = string
}

variable "availability_zone" {
  description = "Availability Zone for the single-host staging deployment."
  type        = string
}

variable "cloudflare_ipv4_cidrs" {
  description = "Cloudflare origin-facing IPv4 ranges allowed to reach HTTPS."
  type        = set(string)
}

variable "tags" {
  description = "Tags applied to all supported resources."
  type        = map(string)
  default     = {}
}
