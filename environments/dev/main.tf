module "providers" {
  source = "../../modules/providers"

  project_name      = var.project_name
  environment       = var.environment
  primary_region    = var.primary_region
  secondary_region  = var.secondary_region
  enable_cloudfront = var.enable_cloudfront
  enable_waf        = var.enable_waf
}

module "dynamodb" {
  source = "../../modules/dynamodb"

  name_prefix      = module.providers.name_prefix
  table_name       = "app"
  primary_region   = var.primary_region
  secondary_region = var.secondary_region

  enable_point_in_time_recovery = false
}
