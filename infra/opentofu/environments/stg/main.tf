module "network" {
  source = "../../modules/network"

  name_prefix           = local.name_prefix
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidr    = var.public_subnet_cidr
  availability_zone     = local.availability_zone
  cloudflare_ipv4_cidrs = toset(data.cloudflare_ip_ranges.edge.ipv4_cidrs)
  tags                  = local.common_tags
}

module "registry" {
  source = "../../modules/registry"

  name_prefix = local.name_prefix
  repository_names = [
    "alienmark",
    "backend",
    "frontend",
  ]
  tags = local.common_tags
}

module "storage_cdn" {
  source = "../../modules/storage-cdn"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
    cloudflare    = cloudflare
  }

  name_prefix            = local.name_prefix
  cloudflare_zone_id     = var.cloudflare_zone_id
  media_hostname         = local.media_domain
  docs_hostname          = local.docs_domain
  application_origin     = "https://${local.application_domain}"
  cloudfront_price_class = var.cloudfront_price_class
  tags                   = local.common_tags
}

module "compute" {
  source = "../../modules/compute"

  name_prefix                       = local.name_prefix
  aws_account_id                    = var.aws_account_id
  aws_region                        = var.aws_region
  subnet_id                         = module.network.public_subnet_id
  security_group_id                 = module.network.origin_security_group_id
  instance_type                     = var.instance_type
  root_volume_size                  = var.root_volume_size
  ami_ssm_parameter_name            = var.ami_ssm_parameter_name
  ecr_repository_arns               = toset(values(module.registry.repository_arns))
  media_bucket_arn                  = module.storage_cdn.media_bucket_arn
  deployment_bucket_arn             = module.storage_cdn.deployment_bucket_arn
  origin_certificate_parameter_name = var.origin_certificate_parameter_name
  origin_private_key_parameter_name = var.origin_private_key_parameter_name
  tags                              = local.common_tags
}

resource "cloudflare_dns_record" "application_origin" {
  for_each = toset([
    local.application_domain,
    local.api_domain,
    local.grafana_domain,
  ])

  zone_id = var.cloudflare_zone_id
  name    = each.value
  content = module.compute.public_ipv4
  type    = "A"
  proxied = true
  ttl     = 1
  comment = "Managed by OpenTofu for the AlienCommons staging origin"
}

module "github_oidc" {
  source = "../../modules/github-oidc"

  name_prefix            = local.name_prefix
  aws_account_id         = var.aws_account_id
  aws_region             = var.aws_region
  github_repository      = var.github_repository
  github_organization_id = var.github_organization_id
  github_repository_id   = var.github_repository_id
  github_environment     = local.environment
  state_bucket_name      = var.state_bucket_name
  ecr_repository_arns    = toset(values(module.registry.repository_arns))
  docs_bucket_arn        = module.storage_cdn.docs_bucket_arn
  deployment_bucket_arn  = module.storage_cdn.deployment_bucket_arn
  cloudfront_distribution_arns = toset([
    module.storage_cdn.docs_distribution_arn,
    module.storage_cdn.media_distribution_arn,
  ])
  instance_arn = module.compute.instance_arn
  tags         = local.common_tags
}

check "staging_account" {
  assert {
    condition     = data.aws_caller_identity.current.account_id == var.aws_account_id
    error_message = "The active AWS credentials do not belong to the configured staging account."
  }
}
