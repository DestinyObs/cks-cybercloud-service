resource "aws_budgets_budget" "main" {
  name         = "${var.project_name}-${var.environment}-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  time_period_start = formatdate("YYYY-MM-01_00:00", timestamp())

  cost_filter {
    name   = "TagKeyValue"
    values = [
      "Project$${var.project_name}",
      "Environment$${var.environment}"
    ]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = var.alert_threshold
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = var.alert_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = var.alert_threshold
    threshold_type            = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.alert_emails
  }

  tags = var.tags
}
