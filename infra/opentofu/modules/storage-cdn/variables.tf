variable "name_prefix" {
  description = "Prefix applied to storage and CDN resources."
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone that owns the staging hostnames."
  type        = string
  sensitive   = true
}

variable "media_hostname" {
  description = "Public staging hostname for user media."
  type        = string
}

variable "docs_hostname" {
  description = "Public staging hostname for documentation."
  type        = string
}

variable "application_origin" {
  description = "Allowed browser origin for media CORS."
  type        = string
}

variable "cloudfront_price_class" {
  description = "CloudFront edge-location price class."
  type        = string
  default     = "PriceClass_All"

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.cloudfront_price_class)
    error_message = "cloudfront_price_class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "tags" {
  description = "Tags applied to all supported resources."
  type        = map(string)
  default     = {}
}
