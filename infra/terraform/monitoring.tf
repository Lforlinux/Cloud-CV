# Cloud CV - Monitoring and Logging Configuration
# SRE/DevOps Engineer Portfolio

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.visitor_counter.function_name}"
  retention_in_days = 14

  tags = merge(local.common_tags, {
    Name = "Cloud-CV-Lambda-Logs"
  })
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/cloud-cv"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "Cloud-CV-API-Gateway-Logs"
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "cloud-cv-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors lambda errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.visitor_counter.function_name
  }

  tags = merge(local.common_tags, {
    Name = "Cloud-CV-Lambda-Errors-Alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "cloud-cv-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "5000"
  alarm_description   = "This metric monitors lambda duration"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    FunctionName = aws_lambda_function.visitor_counter.function_name
  }

  tags = merge(local.common_tags, {
    Name = "Cloud-CV-Lambda-Duration-Alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_throttles" {
  alarm_name          = "cloud-cv-dynamodb-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors DynamoDB throttles"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    TableName = aws_dynamodb_table.visitor_counter.name
  }

  tags = merge(local.common_tags, {
    Name = "Cloud-CV-DynamoDB-Throttles-Alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_4xx_errors" {
  alarm_name          = "cloud-cv-cloudfront-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"
  alarm_description   = "This metric monitors CloudFront 4xx errors"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DistributionId = aws_cloudfront_distribution.website.id
  }

  tags = merge(local.common_tags, {
    Name = "Cloud-CV-CloudFront-4xx-Errors-Alarm"
  })
}

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "cloud-cv-alerts"

  tags = merge(local.common_tags, {
    Name = "Cloud-CV-Alerts-Topic"
  })
}

# SNS Topic Subscription (email)
resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "Cloud-CV-Dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.visitor_counter.function_name],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", aws_dynamodb_table.visitor_counter.name],
            [".", "ConsumedWriteCapacityUnits", ".", "."],
            [".", "ThrottledRequests", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "DynamoDB Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", aws_cloudfront_distribution.website.id],
            [".", "BytesDownloaded", ".", "."],
            [".", "4xxErrorRate", ".", "."],
            [".", "5xxErrorRate", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "CloudFront Metrics"
          period  = 300
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "Cloud-CV-Dashboard"
  })
}

# X-Ray tracing for Lambda
resource "aws_lambda_function" "visitor_counter" {
  filename         = "../lambda/visitor_counter.zip"
  function_name    = "cloud-cv-visitor-counter"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.11"
  timeout         = 30
  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.visitor_counter.name
    }
  }

  tags = merge(local.common_tags, {
    Name = "Cloud-CV-Visitor-Counter"
  })
}

# X-Ray service role
resource "aws_iam_role_policy" "lambda_xray_policy" {
  name = "cloud-cv-lambda-xray-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# Custom metrics for visitor count
resource "aws_cloudwatch_log_metric_filter" "visitor_count" {
  name           = "cloud-cv-visitor-count"
  log_group_name = aws_cloudwatch_log_group.lambda_logs.name
  filter_pattern = "[timestamp, request_id, level=INFO, message=\"Visitor count updated\", count]"

  metric_transformation {
    name      = "VisitorCount"
    namespace = "CloudCV/Custom"
    value     = "$count"
  }
}

# Cost monitoring
resource "aws_cloudwatch_metric_alarm" "monthly_cost" {
  alarm_name          = "cloud-cv-monthly-cost"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"
  statistic           = "Maximum"
  threshold           = "50"
  alarm_description   = "This metric monitors monthly AWS costs"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    Currency = "USD"
  }

  tags = merge(local.common_tags, {
    Name = "Cloud-CV-Monthly-Cost-Alarm"
  })
}

# Variables for monitoring
variable "alert_email" {
  description = "Email address for alerts"
  type        = string
  default     = ""
}

# Outputs for monitoring
output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "lambda_log_group_name" {
  description = "Name of the Lambda log group"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}
