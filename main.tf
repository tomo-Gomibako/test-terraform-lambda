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
