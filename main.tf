terraform {
  required_providers {
    dotenv = {
      source  = "jrhouston/dotenv"
      version = "~> 1.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "dotenv" "dev" {
  filename = "dev.env"
}

locals {
  project_code    = "gomibako"
  resource_prefix = "gomibako"
  project_region  = "ap-northeast-1"
  project_zone    = "a"
}

provider "aws" {
  profile = "default"
  region  = local.project_region

  default_tags {
    tags = {
      project = local.project_code
    }
  }
}

resource "random_pet" "lambda_bucket_name" {
  prefix = local.resource_prefix
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id

  tags = {
    project = local.project_code
  }
}

resource "aws_s3_bucket_ownership_controls" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "lambda_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.lambda_bucket]

  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "dist"
  output_path = "/tmp/lambda_function_payload.zip"
  # excludes = [
  #   ".git",
  #   ".terraform",
  #   "node_modules",
  #   ".terraform.lock.hcl",
  #   ".terraform.tfstate.lock.info",
  #   "dev.env",
  #   "pnpm-lock.yaml",
  #   "terraform.tfstate",
  #   "terraform.tfstate.backup"
  # ]
}

resource "aws_s3_object" "lambda" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "hello-world.zip"
  source = data.archive_file.lambda.output_path

  etag = filemd5(data.archive_file.lambda.output_path)

  tags = {
    project = local.project_code
  }
}

resource "random_pet" "lambda_test-http_name" {
  prefix = local.project_code
  length = 4
}

resource "aws_lambda_function" "test-http" {
  function_name = random_pet.lambda_test-http_name.id

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda.key

  runtime = "nodejs20.x"
  handler = "index.handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  role = aws_iam_role.lambda_exec.arn

  tags = {
    project = local.project_code
  }

  depends_on = [aws_s3_object.lambda]
}

resource "aws_cloudwatch_log_group" "test-http" {
  name = "/aws/lambda/${aws_lambda_function.test-http.function_name}"

  retention_in_days = 30

  tags = {
    project = local.project_code
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })

  tags = {
    project = local.project_code
  }
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"

  tags = {
    project = local.project_code
  }
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }

  tags = {
    project = local.project_code
  }
}

resource "aws_apigatewayv2_integration" "test-http" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.test-http.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "test-http" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.test-http.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30

  tags = {
    project = local.project_code
  }
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test-http.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

output "base_url" {
  value = "${aws_apigatewayv2_stage.lambda.invoke_url}/hello"
}

resource "random_pet" "lambda_test-cron_name" {
  prefix = local.resource_prefix
  length = 4
}

resource "aws_lambda_function" "test-cron" {
  function_name = random_pet.lambda_test-cron_name.id

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda.key

  runtime = "nodejs20.x"
  handler = "index.handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  role = aws_iam_role.lambda_exec.arn

  tags = {
    project = local.project_code
  }

  depends_on = [aws_s3_object.lambda]
}

resource "random_pet" "scheduler_name" {
  prefix = local.resource_prefix
  length = 4
}

data "aws_iam_policy_document" "scheduler" {
  statement {
    actions = [
      "sts:AssumeRole",
      "scheduler:CreateSchedule",
      "scheduler:DeleteSchedule",
      "scheduler:GetSchedule",
      "scheduler:UpdateSchedule",
    ]
    resources = [
      "arn:aws:events:::*",
      "arn:aws:schedule:::*",
    ]
  }
}

resource "aws_iam_policy" "scheduler" {
  name        = "scheduler-policy"
  description = "A scheduler policy"

  policy = data.aws_iam_policy_document.scheduler.json
}

resource "aws_iam_role" "scheduler" {
  name = "lambda_cron_scheduler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service : "scheduler.amazonaws.com"
      }
      }
    ]
  })

  tags = {
    project = local.project_code
  }
}

resource "aws_iam_policy_attachment" "scheduler_policy" {
  name       = "scheduler-attachment"
  roles      = ["${aws_iam_role.scheduler.name}"]
  policy_arn = aws_iam_policy.scheduler.arn
}


resource "aws_scheduler_schedule" "test-cron" {
  name       = random_pet.scheduler_name.id
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(*/10 * * * ? *)"
  schedule_expression_timezone = "Asia/Tokyo"

  target {
    arn      = aws_lambda_function.test-cron.arn
    role_arn = aws_iam_role.lambda_exec.arn
  }
}

