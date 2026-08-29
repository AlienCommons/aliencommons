data "aws_caller_identity" "current" {}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

locals {
  bucket_names = {
    media      = "${var.name_prefix}-media-${data.aws_caller_identity.current.account_id}"
    docs       = "${var.name_prefix}-docs-${data.aws_caller_identity.current.account_id}"
    deployment = "${var.name_prefix}-deployment-${data.aws_caller_identity.current.account_id}"
  }
}

resource "aws_s3_bucket" "this" {
  for_each = local.bucket_names

  bucket = each.value
  tags   = merge(var.tags, { Name = each.value })
}

resource "aws_s3_bucket_ownership_controls" "this" {
  for_each = local.bucket_names

  bucket = aws_s3_bucket.this[each.key].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = local.bucket_names

  bucket                  = aws_s3_bucket.this[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = local.bucket_names

  bucket = aws_s3_bucket.this[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = local.bucket_names

  bucket = aws_s3_bucket.this[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "content" {
  for_each = {
    media = aws_s3_bucket.this["media"]
    docs  = aws_s3_bucket.this["docs"]
  }

  bucket = each.value.id

  rule {
    id     = "expire-old-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

resource "aws_s3_bucket_lifecycle_configuration" "deployment" {
  bucket = aws_s3_bucket.this["deployment"].id

  rule {
    id     = "expire-deployment-artifacts"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

resource "aws_s3_bucket_cors_configuration" "media" {
  bucket = aws_s3_bucket.this["media"].id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = [var.application_origin]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

resource "aws_acm_certificate" "cdn" {
  provider = aws.us_east_1

  domain_name               = var.media_hostname
  subject_alternative_names = [var.docs_hostname]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-cdn" })
}

resource "cloudflare_dns_record" "acm_validation" {
  for_each = {
    for option in aws_acm_certificate.cdn.domain_validation_options : option.domain_name => {
      name    = trimsuffix(option.resource_record_name, ".")
      content = trimsuffix(option.resource_record_value, ".")
      type    = option.resource_record_type
    }
  }

  zone_id = var.cloudflare_zone_id
  name    = each.value.name
  content = each.value.content
  type    = each.value.type
  proxied = false
  ttl     = 60
  comment = "Managed by OpenTofu for the staging CloudFront ACM certificate"
}

resource "aws_acm_certificate_validation" "cdn" {
  provider = aws.us_east_1

  certificate_arn = aws_acm_certificate.cdn.arn
  validation_record_fqdns = [
    for option in aws_acm_certificate.cdn.domain_validation_options : option.resource_record_name
  ]

  depends_on = [cloudflare_dns_record.acm_validation]
}

resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.name_prefix}-s3"
  description                       = "Private staging S3 origins"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "docs_url_rewrite" {
  name    = "${var.name_prefix}-docs-url-rewrite"
  runtime = "cloudfront-js-2.0"
  comment = "Resolve clean documentation URLs to index.html objects"
  publish = true
  code    = file("${path.module}/docs-url-rewrite.js")
}

resource "aws_cloudfront_distribution" "media" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "AlienCommons staging media gateway"
  aliases         = [var.media_hostname]
  price_class     = var.cloudfront_price_class

  origin {
    domain_name              = aws_s3_bucket.this["media"].bucket_regional_domain_name
    origin_id                = "media-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  default_cache_behavior {
    target_origin_id       = "media-s3"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_disabled.id
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cdn.certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-media" })
}

resource "aws_cloudfront_distribution" "docs" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "AlienCommons staging documentation gateway"
  aliases             = [var.docs_hostname]
  default_root_object = "index.html"
  price_class         = var.cloudfront_price_class

  origin {
    domain_name              = aws_s3_bucket.this["docs"].bucket_regional_domain_name
    origin_id                = "docs-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  default_cache_behavior {
    target_origin_id       = "docs-s3"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_disabled.id
    compress               = true

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.docs_url_rewrite.arn
    }
  }

  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 0
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cdn.certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-docs" })
}

data "aws_iam_policy_document" "media_bucket" {
  statement {
    sid     = "AllowCloudFrontRead"
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.this["media"].arn}/*",
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.media.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "media" {
  bucket = aws_s3_bucket.this["media"].id
  policy = data.aws_iam_policy_document.media_bucket.json
}

data "aws_iam_policy_document" "docs_bucket" {
  statement {
    sid     = "AllowCloudFrontRead"
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.this["docs"].arn}/*",
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.docs.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "docs" {
  bucket = aws_s3_bucket.this["docs"].id
  policy = data.aws_iam_policy_document.docs_bucket.json
}

resource "cloudflare_dns_record" "media" {
  zone_id = var.cloudflare_zone_id
  name    = var.media_hostname
  content = aws_cloudfront_distribution.media.domain_name
  type    = "CNAME"
  proxied = true
  ttl     = 1
  comment = "Managed by OpenTofu for AlienCommons staging media"
}

resource "cloudflare_dns_record" "docs" {
  zone_id = var.cloudflare_zone_id
  name    = var.docs_hostname
  content = aws_cloudfront_distribution.docs.domain_name
  type    = "CNAME"
  proxied = true
  ttl     = 1
  comment = "Managed by OpenTofu for AlienCommons staging docs"
}
