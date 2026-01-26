#############################################
# Observability — CloudWatch Dashboard (O4)
#############################################

resource "aws_cloudwatch_dashboard" "global_serverless" {
  dashboard_name = "${module.providers.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "API 4XX / 5XX (Primary eu-west-1)"
          region = var.primary_region
          period = 60
          stat   = "Sum"
          metrics = [
            ["AWS/ApiGateway", "4XXError", "ApiId", module.api_primary.api_id, "Stage", "$default"],
            [".", "5XXError", ".", ".", ".", "."]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "API 4XX / 5XX (Secondary eu-central-1)"
          region = var.secondary_region
          period = 60
          stat   = "Sum"
          metrics = [
            ["AWS/ApiGateway", "4XXError", "ApiId", module.api_secondary.api_id, "Stage", "$default"],
            [".", "5XXError", ".", ".", ".", "."]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "API Latency Avg (Primary eu-west-1)"
          region = var.primary_region
          period = 60
          stat   = "Average"
          metrics = [
            ["AWS/ApiGateway", "Latency", "ApiId", module.api_primary.api_id, "Stage", "$default"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "API Latency Avg (Secondary eu-central-1)"
          region = var.secondary_region
          period = 60
          stat   = "Average"
          metrics = [
            ["AWS/ApiGateway", "Latency", "ApiId", module.api_secondary.api_id, "Stage", "$default"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Lambda Errors (Primary)"
          region = var.primary_region
          period = 60
          stat   = "Sum"
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", module.lambda_primary.function_name]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Lambda Errors (Secondary)"
          region = var.secondary_region
          period = 60
          stat   = "Sum"
          metrics = [
            ["AWS/Lambda", "Errors", "FunctionName", module.lambda_secondary.function_name]
          ]
        }
      }
    ]
  })
}
