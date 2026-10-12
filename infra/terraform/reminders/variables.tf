variable "environment" {
  type = string
}

variable "default_tags" {}

variable "app_url" {
  type = string
}

variable "extra_allowed_origins" {
  type    = list(string)
  default = []
}

variable "dispatch_rate" {
  description = "How often the dispatcher runs"
  type        = string
  default     = "rate(15 minutes)"
}

variable "window_minutes" {
  description = "A reminder is sent if its time passed within this many minutes"
  type        = number
  default     = 60
}

variable "log_retention_days" {
  type    = number
  default = 14
}
