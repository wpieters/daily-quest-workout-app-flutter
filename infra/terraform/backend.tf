terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.99"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    encrypt              = "true"
    bucket               = "piforge-tfstate"
    region               = "ap-northeast-3"
    key                  = "dailyquest.tfstate"
    workspace_key_prefix = "dailyquest"
    profile              = "dailyquest"
  }
}

provider "aws" {
  region              = var.aws_region # Same region as the Amplify app
  allowed_account_ids = ["774305596805"]
  profile             = "dailyquest"

  default_tags {
    tags = local.default_tags
  }
}
