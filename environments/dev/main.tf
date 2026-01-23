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

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${module.providers.name_prefix}-lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_caller_identity" "current" {}

locals {
  ddb_table_arn_primary   = module.dynamodb.table_arn
  ddb_table_arn_secondary = "arn:aws:dynamodb:${var.secondary_region}:${data.aws_caller_identity.current.account_id}:table/${module.dynamodb.table_name}"
}

data "aws_iam_policy_document" "ddb_access" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:DescribeTable"
    ]
    resources = [
      local.ddb_table_arn_primary,
      "${local.ddb_table_arn_primary}/*",
      local.ddb_table_arn_secondary,
      "${local.ddb_table_arn_secondary}/*"
    ]
  }
}

resource "aws_iam_policy" "ddb_policy" {
  name   = "${module.providers.name_prefix}-ddb-access"
  policy = data.aws_iam_policy_document.ddb_access.json
}

resource "aws_iam_role_policy_attachment" "lambda_ddb_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.ddb_policy.arn
}

module "lambda_primary" {
  source = "../../modules/lambda"

  providers = {
    aws = aws
  }

  name_prefix     = module.providers.name_prefix
  function_suffix = "api-primary"
  table_name      = module.dynamodb.table_name
  role_arn        = aws_iam_role.lambda_exec.arn
  source_dir      = abspath("${path.root}/../../src/lambda")

  runtime              = "python3.12"
  log_retention_days   = 3
  reserved_concurrency = null
}

module "lambda_secondary" {
  source = "../../modules/lambda"

  providers = {
    aws = aws.secondary
  }

  name_prefix     = module.providers.name_prefix
  function_suffix = "api-secondary"
  table_name      = module.dynamodb.table_name
  role_arn        = aws_iam_role.lambda_exec.arn
  source_dir      = abspath("${path.root}/../../src/lambda")

  runtime              = "python3.12"
  log_retention_days   = 3
  reserved_concurrency = null
}

module "api_primary" {
  source = "../../modules/api"

  providers = { aws = aws }

  name_prefix          = module.providers.name_prefix
  api_suffix           = "primary"
  lambda_invoke_arn    = module.lambda_primary.invoke_arn
  lambda_function_name = module.lambda_primary.function_name

  log_retention_days   = 3
  throttle_rate_limit  = 5
  throttle_burst_limit = 10
}

module "api_secondary" {
  source = "../../modules/api"

  providers = { aws = aws.secondary }

  name_prefix          = module.providers.name_prefix
  api_suffix           = "secondary"
  lambda_invoke_arn    = module.lambda_secondary.invoke_arn
  lambda_function_name = module.lambda_secondary.function_name

  log_retention_days   = 3
  throttle_rate_limit  = 5
  throttle_burst_limit = 10
}

locals {
  api_fqdn = "${var.api_subdomain}.${var.root_domain}"
}

resource "aws_route53_zone" "public" {
  name = var.root_domain
}

output "route53_nameservers" {
  value = aws_route53_zone.public.name_servers
}

# --- ACM cert in PRIMARY region (eu-west-1) ---
resource "aws_acm_certificate" "api_primary" {
  domain_name       = local.api_fqdn
  validation_method = "DNS"
}

resource "aws_route53_record" "api_primary_cert_validation" {
  allow_overwrite = true

  for_each = {
    for dvo in aws_acm_certificate.api_primary.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.public.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "api_primary" {
  certificate_arn         = aws_acm_certificate.api_primary.arn
  validation_record_fqdns = [for r in aws_route53_record.api_primary_cert_validation : r.fqdn]
}

# --- ACM cert in SECONDARY region (eu-central-1) ---
resource "aws_acm_certificate" "api_secondary" {
  provider          = aws.secondary
  domain_name       = local.api_fqdn
  validation_method = "DNS"
}

resource "aws_route53_record" "api_secondary_cert_validation" {
  allow_overwrite = true

  for_each = {
    for dvo in aws_acm_certificate.api_secondary.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.public.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "api_secondary" {
  provider                = aws.secondary
  certificate_arn         = aws_acm_certificate.api_secondary.arn
  validation_record_fqdns = [for r in aws_route53_record.api_secondary_cert_validation : r.fqdn]
}

# --- API Gateway custom domain in PRIMARY (eu-west-1) ---
resource "aws_apigatewayv2_domain_name" "api_primary" {
  domain_name = local.api_fqdn

  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.api_primary.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "api_primary" {
  api_id      = module.api_primary.api_id
  domain_name = aws_apigatewayv2_domain_name.api_primary.id
  stage       = "$default"
}

# --- API Gateway custom domain in SECONDARY (eu-central-1) ---
resource "aws_apigatewayv2_domain_name" "api_secondary" {
  provider    = aws.secondary
  domain_name = local.api_fqdn

  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.api_secondary.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "api_secondary" {
  provider    = aws.secondary
  api_id      = module.api_secondary.api_id
  domain_name = aws_apigatewayv2_domain_name.api_secondary.id
  stage       = "$default"
}

# Latency routing (A record) - PRIMARY
resource "aws_route53_record" "api_latency_primary_a" {
  zone_id = aws_route53_zone.public.zone_id
  name    = local.api_fqdn
  type    = "A"

  set_identifier = "primary-eu-west-1"

  latency_routing_policy {
    region = var.primary_region
  }

  alias {
    name                   = aws_apigatewayv2_domain_name.api_primary.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_primary.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# Latency routing (A record) - SECONDARY
resource "aws_route53_record" "api_latency_secondary_a" {
  zone_id = aws_route53_zone.public.zone_id
  name    = local.api_fqdn
  type    = "A"

  set_identifier = "secondary-eu-central-1"

  latency_routing_policy {
    region = var.secondary_region
  }

  alias {
    name                   = aws_apigatewayv2_domain_name.api_secondary.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_secondary.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# Latency routing (AAAA record) - PRIMARY
resource "aws_route53_record" "api_latency_primary_aaaa" {
  zone_id = aws_route53_zone.public.zone_id
  name    = local.api_fqdn
  type    = "AAAA"

  set_identifier = "primary-eu-west-1-aaaa"

  latency_routing_policy {
    region = var.primary_region
  }

  alias {
    name                   = aws_apigatewayv2_domain_name.api_primary.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_primary.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# Latency routing (AAAA record) - SECONDARY
resource "aws_route53_record" "api_latency_secondary_aaaa" {
  zone_id = aws_route53_zone.public.zone_id
  name    = local.api_fqdn
  type    = "AAAA"

  set_identifier = "secondary-eu-central-1-aaaa"

  latency_routing_policy {
    region = var.secondary_region
  }

  alias {
    name                   = aws_apigatewayv2_domain_name.api_secondary.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_secondary.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
