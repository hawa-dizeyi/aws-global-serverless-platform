module "providers" {
  source = "../../modules/providers"

  project_name      = var.project_name
  environment       = var.environment
  primary_region    = var.primary_region
  secondary_region  = var.secondary_region
  enable_cloudfront = var.enable_cloudfront
  enable_waf        = var.enable_waf
}
