output "name_prefix" {
  value = module.providers.name_prefix
}

output "regions" {
  value = module.providers.regions
}

output "feature_flags" {
  value = module.providers.feature_flags
}

output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  value = module.dynamodb.table_arn
}
