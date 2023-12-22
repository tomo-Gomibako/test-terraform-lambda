# provider "aws" {
#   region = "ap-northeast-1"

#   # Make it faster by skipping something
#   # skip_metadata_api_check     = true
#   # skip_region_validation      = true
#   # skip_credentials_validation = true
#   # skip_requesting_account_id  = true
# }

module "eventbridge" {
  source = "terraform-aws-modules/eventbridge/aws"

  create_bus = false

  rules = {
    crons = {
      description         = "Trigger for a Lambda"
      schedule_expression = "rate(5 minutes)"
    }
  }

  targets = {
    crons = [
      {
        name  = local.resource_prefix
        arn   = module.lambda.lambda_function_arn
        input = jsonencode("World")
      }
    ]
  }

  tags = {
    "project" = local.project_code
  }
}

##################
# Extra resources
##################

resource "random_pet" "this" {
  length = 2
}

#############################################
# Using packaged function from Lambda module
#############################################

module "lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 2.0"

  function_name = "${random_pet.this.id}-lambda"
  runtime       = "nodejs20.x"
  handler       = "index.cronHandler"

  create_package         = false
  local_existing_package = data.archive_file.lambda.output_path

  create_current_version_allowed_triggers = false
  allowed_triggers = {
    ScanAmiRule = {
      principal  = "events.amazonaws.com"
      source_arn = module.eventbridge.eventbridge_rule_arns["crons"]
    }
  }

  tags = {
    "project" = local.project_code
  }
}

# locals {
#   package_url = "https://raw.githubusercontent.com/terraform-aws-modules/terraform-aws-lambda/master/examples/fixtures/python3.8-zip/existing_package.zip"
#   downloaded  = "downloaded_package_${md5(local.package_url)}.zip"
# }

# resource "null_resource" "download_package" {
#   triggers = {
#     downloaded = local.downloaded
#   }

#   provisioner "local-exec" {
#     command = "curl -L -o ${local.downloaded} ${local.package_url}"
#   }
# }

