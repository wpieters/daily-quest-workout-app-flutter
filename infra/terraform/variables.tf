locals {
  default_tags = {
    Project     = "dailyquest"
    Client      = "piforge"
    Environment = var.environment
  }
}

variable "environment" {
  type    = string
  default = "production"
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "app_url" {
  description = "Where the PWA is served; used for CORS and as the notification link"
  type        = string
  default     = "https://dailyquest.duhblinn.xyz"
}

variable "extra_allowed_origins" {
  description = "Additional CORS origins, e.g. a local dev server"
  type        = list(string)
  default     = []
}
