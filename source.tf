locals {
  source_zip_filename = "hello-world.zip"
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

  key    = local.source_zip_filename
  source = data.archive_file.lambda.output_path

  etag = filemd5(data.archive_file.lambda.output_path)

  tags = {
    project = local.project_code
  }
}
