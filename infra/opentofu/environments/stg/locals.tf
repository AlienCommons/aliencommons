locals {
  project            = "aliencommons"
  environment        = "stg"
  name_prefix        = "${local.project}-${local.environment}"
  availability_zone  = coalesce(var.availability_zone, data.aws_availability_zones.available.names[0])
  root_domain        = "aliencommons.com"
  application_domain = "stg.${local.root_domain}"
  api_domain         = "api.stg.${local.root_domain}"
  grafana_domain     = "grafana.stg.${local.root_domain}"
  media_domain       = "media.stg.${local.root_domain}"
  docs_domain        = "docs.stg.${local.root_domain}"

  common_tags = {
    Project     = local.project
    Environment = local.environment
    ManagedBy   = "opentofu"
    Repository  = var.github_repository
  }
}
