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
      module.dynamodb.table_arn,
      "${module.dynamodb.table_arn}/*"
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
