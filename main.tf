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
  project_id     = "gomibako"
  project_region = "ap-northeast-1"
  project_zone   = "a"
}

provider "aws" {
  profile = "default"
  region  = local.project_region
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "."
  output_path = "/tmp/lambda_function_payload.zip"
  excludes = [
    ".git",
    ".terraform",
    "node_modules",
    ".terraform.lock.hcl",
    ".terraform.tfstate.lock.info",
    "dev.env",
    "pnpm-lock.yaml",
    "terraform.tfstate",
    "terraform.tfstate.backup"
  ]
}

resource "aws_lambda_function" "test_lambda" {
  filename      = data.archive_file.lambda.output_path
  function_name = "lambda_function_name"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.test"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "nodejs20.x"

  environment {
    variables = {
      foo = "bar"
    }
  }
}
