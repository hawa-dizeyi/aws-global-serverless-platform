output "name_prefix" {
  value = local.name_prefix
}

output "regions" {
  value = {
    primary   = var.primary_region
    secondary = var.secondary_region
  }
}

output "feature_flags" {
  value = {
    cloudfront = var.enable_cloudfront
    waf        = var.enable_waf
  }
}
