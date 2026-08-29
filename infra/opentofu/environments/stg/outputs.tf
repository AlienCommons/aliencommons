output "infrastructure_role_arn" {
  value     = module.github_oidc.infrastructure_role_arn
  sensitive = true
}

output "deploy_role_arn" {
  value     = module.github_oidc.deploy_role_arn
  sensitive = true
}

output "instance_id" {
  value     = module.compute.instance_id
  sensitive = true
}

output "origin_ipv4" {
  value     = module.compute.public_ipv4
  sensitive = true
}

output "ecr_repository_urls" {
  value     = module.registry.repository_urls
  sensitive = true
}

output "media_bucket_name" {
  value     = module.storage_cdn.media_bucket_name
  sensitive = true
}

output "docs_bucket_name" {
  value     = module.storage_cdn.docs_bucket_name
  sensitive = true
}

output "deployment_bucket_name" {
  value     = module.storage_cdn.deployment_bucket_name
  sensitive = true
}

output "docs_distribution_id" {
  value     = module.storage_cdn.docs_distribution_id
  sensitive = true
}

output "media_distribution_id" {
  value     = module.storage_cdn.media_distribution_id
  sensitive = true
}
