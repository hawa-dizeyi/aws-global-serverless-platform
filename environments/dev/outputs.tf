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

output "lambda_primary_name" {
  value = module.lambda_primary.function_name
}

output "lambda_secondary_name" {
  value = module.lambda_secondary.function_name
}
