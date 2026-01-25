variable "name_prefix" {
  type        = string
  description = "Name prefix for resources."
}

variable "api_suffix" {
  type        = string
  description = "Suffix for API name, e.g. primary or secondary."
}

variable "lambda_invoke_arn" {
  type        = string
  description = "Lambda invoke ARN (regional)."
}

variable "lambda_function_name" {
  type        = string
  description = "Lambda function name (for permissions)."
}

variable "log_retention_days" {
  type        = number
  default     = 3
}

variable "throttle_rate_limit" {
  type        = number
  default     = 5
  description = "Steady-state requests per second per route."
}

variable "throttle_burst_limit" {
  type        = number
  default     = 10
  description = "Burst requests per second per route."
}

variable "cors_allow_origins" {
  type        = list(string)
  description = "Allowed browser origins for CORS."
  default     = []
}
