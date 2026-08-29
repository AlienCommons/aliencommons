output "media_bucket_arn" {
  value = aws_s3_bucket.this["media"].arn
}

output "media_bucket_name" {
  value = aws_s3_bucket.this["media"].id
}

output "docs_bucket_arn" {
  value = aws_s3_bucket.this["docs"].arn
}

output "docs_bucket_name" {
  value = aws_s3_bucket.this["docs"].id
}

output "deployment_bucket_arn" {
  value = aws_s3_bucket.this["deployment"].arn
}

output "deployment_bucket_name" {
  value = aws_s3_bucket.this["deployment"].id
}

output "media_distribution_arn" {
  value = aws_cloudfront_distribution.media.arn
}

output "media_distribution_id" {
  value = aws_cloudfront_distribution.media.id
}

output "docs_distribution_arn" {
  value = aws_cloudfront_distribution.docs.arn
}

output "docs_distribution_id" {
  value = aws_cloudfront_distribution.docs.id
}
