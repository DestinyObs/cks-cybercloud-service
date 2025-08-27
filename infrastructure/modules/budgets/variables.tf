variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
}

variable "alert_threshold" {
  description = "Budget alert threshold percentage"
  type        = number
}

variable "alert_emails" {
  description = "Email addresses for budget alerts"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
