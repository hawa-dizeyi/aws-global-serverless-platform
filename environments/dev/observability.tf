#############################################
# Observability — CloudWatch Alarms (O1)
#############################################

locals {
  api_stage_name = "$default"
}

# -------------------------
# PRIMARY (eu-west-1)
# -------------------------

resource "aws_cloudwatch_metric_alarm" "api_5xx_primary" {
  alarm_name          = "${module.providers.name_prefix}-api-5xx-primary"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/ApiGateway"
  metric_name = "5XXError"

  dimensions = {
    ApiId = module.api_primary.api_id
    Stage = local.api_stage_name
  }
}

resource "aws_cloudwatch_metric_alarm" "api_4xx_primary" {
  alarm_name          = "${module.providers.name_prefix}-api-4xx-primary"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 60
  statistic           = "Sum"
  threshold           = 20
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/ApiGateway"
  metric_name = "4XXError"

  dimensions = {
    ApiId = module.api_primary.api_id
    Stage = local.api_stage_name
  }
}

resource "aws_cloudwatch_metric_alarm" "api_latency_primary" {
  alarm_name          = "${module.providers.name_prefix}-api-latency-primary"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  period              = 60
  statistic           = "Average"
  threshold           = 1500
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/ApiGateway"
  metric_name = "Latency"

  dimensions = {
    ApiId = module.api_primary.api_id
    Stage = local.api_stage_name
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors_primary" {
  alarm_name          = "${module.providers.name_prefix}-lambda-errors-primary"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/Lambda"
  metric_name = "Errors"

  dimensions = {
    FunctionName = module.lambda_primary.function_name
  }
}

# -------------------------
# SECONDARY (eu-central-1)
# -------------------------

resource "aws_cloudwatch_metric_alarm" "api_5xx_secondary" {
  provider            = aws.secondary
  alarm_name          = "${module.providers.name_prefix}-api-5xx-secondary"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/ApiGateway"
  metric_name = "5XXError"

  dimensions = {
    ApiId = module.api_secondary.api_id
    Stage = local.api_stage_name
  }
}

resource "aws_cloudwatch_metric_alarm" "api_4xx_secondary" {
  provider            = aws.secondary
  alarm_name          = "${module.providers.name_prefix}-api-4xx-secondary"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 60
  statistic           = "Sum"
  threshold           = 20
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/ApiGateway"
  metric_name = "4XXError"

  dimensions = {
    ApiId = module.api_secondary.api_id
    Stage = local.api_stage_name
  }
}

resource "aws_cloudwatch_metric_alarm" "api_latency_secondary" {
  provider            = aws.secondary
  alarm_name          = "${module.providers.name_prefix}-api-latency-secondary"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  period              = 60
  statistic           = "Average"
  threshold           = 1500
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/ApiGateway"
  metric_name = "Latency"

  dimensions = {
    ApiId = module.api_secondary.api_id
    Stage = local.api_stage_name
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors_secondary" {
  provider            = aws.secondary
  alarm_name          = "${module.providers.name_prefix}-lambda-errors-secondary"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/Lambda"
  metric_name = "Errors"

  dimensions = {
    FunctionName = module.lambda_secondary.function_name
  }
}
