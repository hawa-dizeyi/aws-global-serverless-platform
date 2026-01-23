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
