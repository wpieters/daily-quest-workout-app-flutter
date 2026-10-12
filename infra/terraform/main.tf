# DailyQuest Infrastructure
# Region: us-east-1 (same as the Amplify app)
#
# The PWA itself is built and hosted by Amplify (see ../../amplify.yml). This
# covers only what the app can't do on-device: Web Push reminders (ADR 0012).

# -----------------------------------------------------
# REMINDERS (Web Push)
# -----------------------------------------------------
module "reminders" {
  source                = "./reminders"
  environment           = var.environment
  default_tags          = local.default_tags
  app_url               = var.app_url
  extra_allowed_origins = var.extra_allowed_origins
}

# -----------------------------------------------------
# Outputs
# -----------------------------------------------------
output "reminders_api_url" {
  description = "Base URL of the reminders API; the app needs this at build time"
  value       = module.reminders.api_url
}

output "reminders_table_name" {
  description = "DynamoDB table holding push subscriptions"
  value       = module.reminders.table_name
}
