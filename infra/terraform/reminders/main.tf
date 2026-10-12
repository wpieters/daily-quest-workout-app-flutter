locals {
  name       = "dailyquest-reminders-${var.environment}"
  lambda_src = "${path.module}/../../lambda/reminders"
  origins    = concat([var.app_url], var.extra_allowed_origins)
}

# -----------------------------------------------------
# DynamoDB: one item per push subscription
# -----------------------------------------------------
resource "aws_dynamodb_table" "subscriptions" {
  name         = local.name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Subscriptions the app stops refreshing expire on their own.
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = var.default_tags
}

# -----------------------------------------------------
# VAPID key: generated once, kept in SSM, never in the app
# -----------------------------------------------------
resource "tls_private_key" "vapid" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "aws_ssm_parameter" "vapid" {
  name  = "/dailyquest/${var.environment}/reminders/vapid-private-key"
  type  = "SecureString"
  value = tls_private_key.vapid.private_key_pem
  tags  = var.default_tags
}

# -----------------------------------------------------
# Lambda package: both functions share one zip
# -----------------------------------------------------
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = local.lambda_src
  output_path = "${path.module}/.build/reminders.zip"
  excludes    = ["reminders.test.mjs", "package-lock.json"]
}

# -----------------------------------------------------
# IAM: one role, scoped to the table and the key
# -----------------------------------------------------
data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    sid = "Subscriptions"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Scan",
    ]
    resources = [aws_dynamodb_table.subscriptions.arn]
  }

  statement {
    sid       = "VapidKey"
    actions   = ["ssm:GetParameter"]
    resources = [aws_ssm_parameter.vapid.arn]
  }
}

resource "aws_iam_role" "lambda" {
  name               = local.name
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.default_tags
}

resource "aws_iam_role_policy" "lambda" {
  name   = "reminders"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda.json
}

resource "aws_iam_role_policy_attachment" "logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# -----------------------------------------------------
# API Lambda + Function URL
# -----------------------------------------------------
resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/lambda/${local.name}-api"
  retention_in_days = var.log_retention_days
  tags              = var.default_tags
}

resource "aws_lambda_function" "api" {
  function_name    = "${local.name}-api"
  role             = aws_iam_role.lambda.arn
  runtime          = "nodejs22.x"
  handler          = "api.handler"
  architectures    = ["arm64"]
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 10
  memory_size      = 256

  # Public endpoint: cap how hard it can be hammered.
  reserved_concurrent_executions = 2

  environment {
    variables = {
      TABLE_NAME           = aws_dynamodb_table.subscriptions.name
      VAPID_PARAMETER_NAME = aws_ssm_parameter.vapid.name
    }
  }

  depends_on = [aws_cloudwatch_log_group.api, aws_iam_role_policy.lambda]
  tags       = var.default_tags
}

resource "aws_lambda_function_url" "api" {
  function_name      = aws_lambda_function.api.function_name
  authorization_type = "NONE"

  cors {
    allow_origins = local.origins
    allow_methods = ["GET", "PUT", "POST", "DELETE"]
    allow_headers = ["content-type"]
    max_age       = 3600
  }
}

# Since October 2025 a public Function URL needs both permissions: the URL
# one, and InvokeFunction restricted to calls that arrive via the URL.
resource "aws_lambda_permission" "api_url" {
  statement_id           = "AllowPublicFunctionUrl"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.api.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_permission" "api_url_invoke" {
  statement_id             = "AllowPublicFunctionUrlInvoke"
  action                   = "lambda:InvokeFunction"
  function_name            = aws_lambda_function.api.function_name
  principal                = "*"
  invoked_via_function_url = true
}

# -----------------------------------------------------
# Dispatch Lambda on a schedule
# -----------------------------------------------------
resource "aws_cloudwatch_log_group" "dispatch" {
  name              = "/aws/lambda/${local.name}-dispatch"
  retention_in_days = var.log_retention_days
  tags              = var.default_tags
}

resource "aws_lambda_function" "dispatch" {
  function_name    = "${local.name}-dispatch"
  role             = aws_iam_role.lambda.arn
  runtime          = "nodejs22.x"
  handler          = "dispatch.handler"
  architectures    = ["arm64"]
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 60
  memory_size      = 256

  # Runs must not overlap, or a slot could be sent twice.
  reserved_concurrent_executions = 1

  environment {
    variables = {
      TABLE_NAME           = aws_dynamodb_table.subscriptions.name
      VAPID_PARAMETER_NAME = aws_ssm_parameter.vapid.name
      APP_URL              = var.app_url
      WINDOW_MINUTES       = tostring(var.window_minutes)
    }
  }

  depends_on = [aws_cloudwatch_log_group.dispatch, aws_iam_role_policy.lambda]
  tags       = var.default_tags
}

resource "aws_cloudwatch_event_rule" "dispatch" {
  name                = "${local.name}-dispatch"
  schedule_expression = var.dispatch_rate
  tags                = var.default_tags
}

resource "aws_cloudwatch_event_target" "dispatch" {
  rule = aws_cloudwatch_event_rule.dispatch.name
  arn  = aws_lambda_function.dispatch.arn
}

resource "aws_lambda_permission" "dispatch_schedule" {
  statement_id  = "AllowEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dispatch.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.dispatch.arn
}
